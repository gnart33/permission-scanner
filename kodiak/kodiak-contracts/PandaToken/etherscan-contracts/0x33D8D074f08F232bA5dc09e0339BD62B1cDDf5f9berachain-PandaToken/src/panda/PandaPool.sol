// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "src/interfaces/IWETH.sol";
import "src/interfaces/IPandaFactory.sol";
import "src/libraries/TransferHelper.sol";
import {PandaMath} from "src/libraries/PandaMath.sol";
//import "forge-std/console.sol";

//Panda Pools bonding curve work like providing single-sided liquidity into a UniV3 style dex.
//Since all the liquidity is provided in the token and there are no other liquidity providers, this simplifies to a swapping within a single-tick case in UniV3
abstract contract PandaPool is ReentrancyGuard {
    using Math for uint256;
    IPandaFactory public pandaFactory;
    address public pandaToken; //pandaToken
    address public baseToken; //baseToken

    address public treasury;
    address internal constant DEADADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant GRADUATION_THRESHOLD = 25; //Move liquidity when this many bps of the pool remains (< 25 bps)

    //Fees
    IPandaStructs.PandaFees public poolFees;

    //Deployer
    address public deployer; //User that deployed the pool

    //Note the pool settings are analogous to single-sided liquidity provision on uniswap
    //Pool configs (inputs)
    uint256 public sqrtPa; //sqrt(P_a), sqrt of lower bound price
    uint256 public sqrtPb; //sqrt(P_b), sqrt of upper bound price
    uint256 public totalTokens; //Total tokens in pool
    uint256 public minTradeSize; //Minimum trade size in baseToken
    uint256 public vestingPeriod; //Vesting period for deployer incentives
    address public wbera; //Wrapped Bera address to enable native BERA swaps

    //Pool settings (calculated, constant)
    uint256 public tokensForLp;
    uint256 public tokensInPool;
    uint256 public totalRaise; //Total base token raised with fees to complete the pool
    uint256 public liquidity; //L, which is constant given P_a, P_b, and tokensInPool. L = tokensInPool * (sqrtPa * sqrtPb) / (sqrtPb - sqrtPa)

    //Pool state (variables, tracks how much has been bought/sold in the pool)
    uint256 public sqrtP; //sqrt(P), current price, ranges from sqrtPa to sqrtPb
    uint256 public pandaReserve; //amount of panda token in pool (real reserve, not virtual)
    uint256 public baseReserve; //amount of base token in pool (real reserve, not virtual)

    bool private initialized; //PandaPool initialized (can only be done once, by factory)

    mapping(address => uint256) public tokensBoughtInPool; //net amount each user has bought (regardless of transfers)
    mapping(address => uint256) public tokensClaimed; //amount each user has claimed (when vesting is on)

    //Graduation state
    bool public graduated = false; //Flag to mark pool as graduated (after moveLiquidity is called)
    uint256 public graduationTime; //Time of graduation

    // called once by the factory at time of deployment
    function initializePool(
        address _pandaToken,
        IPandaStructs.PandaPoolParams calldata pp,
        uint256 _totalTokens,
        address _deployer,
        bytes calldata data
    ) external {
        require(!initialized, "PandaPool: ALREADY_INITIALIZED");
        pandaFactory = IPandaFactory(msg.sender);

        _beforeInitializePool(data);

        treasury = pandaFactory.treasury();
        IPandaStructs.PandaFees memory _poolFees = pandaFactory.getPoolFees();
        require(_poolFees.buyFee <= PandaMath.MAX_FEE && _poolFees.sellFee <= PandaMath.MAX_FEE &&
                _poolFees.graduationFee <= PandaMath.MAX_FEE && _poolFees.deployerFeeShare <= PandaMath.MAX_DEPLOYER_FEE_SHARE,
                "PandaPool: FEES_MISCONFIGURED");
        poolFees = _poolFees;

        require(_pandaToken != pp.baseToken, "PandaPool: IDENTICAL_ADDRESSES");
        require(_pandaToken != address(0) && pp.baseToken != address(0), "PandaPool: ZERO_ADDRESS");

        pandaToken = _pandaToken;
        baseToken = pp.baseToken;
        wbera = pandaFactory.wbera();

        totalTokens = _totalTokens;

        require(pp.sqrtPb > pp.sqrtPa, "PandaPool: PRICE_MISCONFIGURED");
        require(pp.sqrtPa > 0, "PandaPool: INVALID_START_PRICE");

        uint256 _tokensInPool = getTokensInPool(pp.sqrtPa, pp.sqrtPb, _totalTokens, _poolFees.graduationFee);
        require(tokensInPool <= totalTokens, "PandaPool: INVALID_TOKENSINPOOL");
        tokensInPool = _tokensInPool;
        tokensForLp = _totalTokens - tokensInPool;

        //initialize sqrtPrice and liquidity, used for price curve calcs
        sqrtPa = pp.sqrtPa;
        sqrtPb = pp.sqrtPb;
        liquidity = tokensInPool.mulDiv(pp.sqrtPa * pp.sqrtPb, pp.sqrtPb - pp.sqrtPa, Math.Rounding.Down);
        totalRaise = PandaMath.getTotalRaise(pp.sqrtPa, pp.sqrtPb, _tokensInPool);

        //initialize reserves and sqrtP
        _update(tokensInPool, 0, sqrtPa);

        minTradeSize = pandaFactory.minTradeSize(baseToken);
        deployer = _deployer;
        vestingPeriod = pp.vestingPeriod;

        initialized = true;

        _afterInitializePool(data);

        emit PoolInitialized(
            _pandaToken,
            pp.baseToken,
            pp.sqrtPa,
            pp.sqrtPb,
            pp.vestingPeriod,
            _deployer,
            data
        );
    }

    //***********************IMPLEMENTATION DETAILS***********************************
    function VERSION() external virtual pure returns (string memory);
    //Hooks to implement custom logic
    function _beforeInitializePool(bytes calldata data) internal virtual {}
    function _afterInitializePool(bytes calldata data) internal virtual {}

    //flag to note if the pool is for a pandaToken that's also being deployed. Default true, override if not
    //This means that by default, the PandaFactory will use defaults associated with pandaToken pools
    function isPandaToken() external view virtual returns (bool) {
        return true;
    }

    //flag to note when incentives can be claimed. Default is if pool has graduated
    function canClaimIncentive() external view virtual returns (bool) {
        return graduated;
    }

    //Calculate tokens to be sold in the pool (vs tokens for LP)
    //Default logic calculated here, see notes in PandaMath library
    //Can be overriden for more advanced logic that's based on how moveLiquidity works
    function getTokensInPool(uint256 _sqrtPa, uint256 _sqrtPb, uint256 _totalTokens, uint16 _graduationFee) public view virtual returns (uint256) {
        return PandaMath.getTokensInPool(_sqrtPa, _sqrtPb, _totalTokens, _graduationFee);
    }

    //Helper function to determine total raise using only deployment parameters
    function getTotalRaise(uint256 _sqrtPa, uint256 _sqrtPb, uint256 _tokensInPool) public view virtual returns (uint256) {
        return PandaMath.getTotalRaise(_sqrtPa, _sqrtPb, _tokensInPool);
    }

    //Normally, moveLiquidity will auto-trigger if buyTokens flips over the graduation threshold
    //This is an external function than can be called by anyone (e.g. bots) to trigger graduation
    function moveLiquidity() external virtual nonReentrant {
        require(!graduated, "PandaPool: GRADUATED");
        require(pandaReserve <= tokensInPool * GRADUATION_THRESHOLD / PandaMath.FEE_SCALE, "PandaPool: POOL_NOT_EMPTY");
        _moveLiquidity();
    }

    //Implement custom logic in implementation
    function _moveLiquidity() internal virtual {}

    //***********************MODIFIERS***********************************************
    modifier notGraduated() {
        require(!graduated, "PandaPool: GRADUATED");
        _;
    }

    modifier onlyBeraPair() {
        require(wbera == baseToken, "PandaPool: NOT_BERA_PAIR");
        _;
    }

    //***********************POOL STATE***********************************************
    function getCurrentPrice() public view returns (uint256) {
        return sqrtP*sqrtP;
    }

    //Update pool state (reserves and sqrtP)
    function _update(uint256 _pandaReserve, uint256 _baseReserve, uint256 _sqrtP) internal {
        //Update reserves
        sqrtP = _sqrtP;
        pandaReserve = _pandaReserve;
        baseReserve = _baseReserve;

        require(pandaReserve <= IERC20(pandaToken).balanceOf(address(this)) - tokensForLp &&
                baseReserve <= IERC20(baseToken).balanceOf(address(this)), "PandaPool: RESERVE_OVERFLOW");

        emit Sync(pandaReserve, baseReserve, sqrtP);
    }

    //***********************SWAP FUNCTIONS*******************************************
    function buyTokensWithBera(uint256 minAmountOut, address to) external payable onlyBeraPair nonReentrant returns (uint256 amountOut, uint256 fee) {
        IWETH(baseToken).deposit{value: msg.value}();
        return _buyTokens(msg.value, minAmountOut, address(this), to);
    }

    function buyTokens(uint256 amountIn, uint256 minAmountOut, address to) external nonReentrant returns (uint256 amountOut, uint256 fee) {
        return _buyTokens(amountIn, minAmountOut, msg.sender, to);
    }

    //"to" must be the end-user to properly increment their tokenBoughtInPool balance
    //This method allows external contracts (routers, bots) to call with "from" and "to" as the end-user
    //Otherwise, it can allow others to swap on behalf of the end-user without authorization (if they gave approval)
    function buyTokens(uint256 amountIn, uint256 minAmountOut, address from, address to) external nonReentrant returns (uint256 amountOut, uint256 fee) {
        require(msg.sender == from || (msg.sender != from && from == tx.origin && to == tx.origin), "PandaPool: INVALID_FROM_TO");
        return _buyTokens(amountIn, minAmountOut, from, to);
    }

    function buyAllTokens(address to) external nonReentrant returns (uint256 amountOut, uint256 fee) {
        uint256 minAmountOut = pandaReserve*9900/10000;
        return _buyTokens(getAmountInBuyRemainingTokens(), minAmountOut, msg.sender, to);
    }

    function _buyTokens(uint256 amountIn, uint256 minAmountOut, address from, address to) internal returns (uint256 amountOut, uint256 fee) {
        require(to != address(0), "PandaPool: INVALID_TO");
        uint256 sqrtP_new;
        (amountOut, fee, sqrtP_new) = getAmountOutBuy(amountIn);
        require(amountOut >= minAmountOut, "PandaPool: INSUFFICIENT_OUTPUT_AMOUNT");

        //Transfers
        if(from != address(this)) {
            TransferHelper.safeTransferFrom(baseToken, from, address(this), amountIn);
        }
        if(vestingPeriod == 0) {
            TransferHelper.safeTransfer(pandaToken, to, amountOut);
        } else {
            tokensBoughtInPool[to] += amountOut; //keep track of amount bought if vesting is on
        }
        TransferHelper.safeTransfer(baseToken, treasury, fee);

        //Update reserves
        uint256 baseReserve_new = baseReserve + amountIn - fee;
        uint256 pandaReserve_new = pandaReserve - amountOut;
        _update(pandaReserve_new, baseReserve_new, sqrtP_new);

        emit Swap(msg.sender, 0, amountIn, amountOut, 0, to);

        //Move liquidity if token reserve is depleted
        if(pandaReserve_new <= tokensInPool * GRADUATION_THRESHOLD / PandaMath.FEE_SCALE) {
            _moveLiquidity();
        }
    }

    function sellTokensForBera(uint256 amountIn, uint256 minAmountOut, address to) external onlyBeraPair nonReentrant returns (uint256 amountOut, uint256 fee) {
        (amountOut, fee) = _sellTokens(amountIn, minAmountOut, msg.sender, address(this));
        IWETH(baseToken).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    function sellTokens(uint256 amountIn, uint256 minAmountOut, address to) external nonReentrant returns (uint256 amountOut, uint256 fee) {
        return _sellTokens(amountIn, minAmountOut, msg.sender, to);
    }

    //"from" must be the end-user to recognize their tokenBoughtInPool balance
    //This method allows external contracts (routers, bots) to call with "from" and "to" as the end-user
    //Otherwise, it can allow others to swap on behalf of the end-user without authorization
    function sellTokens(uint256 amountIn, uint256 minAmountOut, address from, address to) external nonReentrant returns (uint256 amountOut, uint256 fee) {
        require(msg.sender == from || (msg.sender != from && from == tx.origin && to == tx.origin), "PandaPool: INVALID_FROM_TO");
        return _sellTokens(amountIn, minAmountOut, from, to);
    }

    function _sellTokens(uint256 amountIn, uint256 minAmountOut, address from, address to) internal returns (uint256 amountOut, uint256 fee) {
        require(to != address(0), "PandaPool: INVALID_TO");
        uint256 sqrtP_new;
        (amountOut, fee, sqrtP_new) = getAmountOutSell(amountIn);
        require(amountOut >= minAmountOut, "PandaPool: INSUFFICIENT_OUTPUT_AMOUNT");

        //Transfers
        if(vestingPeriod == 0) {
            TransferHelper.safeTransferFrom(pandaToken, from, address(this), amountIn);
        } else {
            //if vesting is on, we track balances with tokensBoughtInPool
            require(amountIn <= tokensBoughtInPool[from], "PandaPool: INSUFFICIENT_VESTED_BOUGHT");
            tokensBoughtInPool[from] -= amountIn;
        }
        if(to != address(this)) {
            TransferHelper.safeTransfer(baseToken, to, amountOut);
        }
        TransferHelper.safeTransfer(baseToken, treasury, fee);

        //Update reserves
        uint256 baseReserve_new = baseReserve - amountOut - fee;
        uint256 pandaReserve_new = pandaReserve + amountIn;

        _update(pandaReserve_new, baseReserve_new, sqrtP_new);

        emit Swap(msg.sender, amountIn, 0, 0, amountOut, to);
    }

    //**************VIEW FUNCTIONS TO CALCULATE SWAP AMOUNTS**************************
    //Buy = swap baseToken for pandaToken
    //@param amountIn: how much baseToken user is swapping
    //@return amountOut: how much pandaToken they will get
    function getAmountOutBuy(uint256 amountIn) notGraduated public view returns (uint256 amountOut, uint256 fee, uint256 sqrtP_new) {
        require(amountIn + 1 gwei >= minTradeSize, "PandaPool: TRADE_BELOW_MIN");
        require(amountIn <= getAmountInBuyRemainingTokens(), "PandaPool: INSUFFICIENT_LIQUIDITY");
        fee = amountIn.mulDiv(poolFees.buyFee, PandaMath.FEE_SCALE, Math.Rounding.Up);
        uint256 deltaBaseReserve = amountIn - fee;
        uint256 baseReserve_new = baseReserve + deltaBaseReserve;
        sqrtP_new = sqrtPa + baseReserve_new.mulDiv(PandaMath.PRICE_SCALE, liquidity, Math.Rounding.Down);

        if(sqrtP_new > sqrtPb) sqrtP_new = sqrtPb;

        uint256 pandaReserve_new = liquidity.mulDiv(sqrtPb - sqrtP_new, sqrtP_new * sqrtPb, Math.Rounding.Up);
        amountOut = pandaReserve - pandaReserve_new;
    }

    //Sell = swap pandaToken for baseToken
    //@param amountIn: how much pandaToken user is swapping
    //@return amountOut: how much baseToken they will get
    function getAmountOutSell(uint256 amountIn) notGraduated public view returns (uint256 amountOut, uint256 fee, uint256 sqrtP_new) {
        uint256 pandaReserve_new = pandaReserve + amountIn; //panda reserve goes up
        sqrtP_new = liquidity.mulDiv(sqrtPb, (pandaReserve_new * sqrtPb + liquidity), Math.Rounding.Up);

        if(sqrtP_new < sqrtPa) sqrtP_new = sqrtPa;

        uint256 baseReserve_new = liquidity.mulDiv(sqrtP_new - sqrtPa, PandaMath.PRICE_SCALE, Math.Rounding.Up);
        require(baseReserve >= baseReserve_new, "PandaPool: INSUFFICIENT_LIQUIDITY");

        uint256 deltaBaseReserve = baseReserve - baseReserve_new;
        require(deltaBaseReserve + 1 gwei >= minTradeSize, "PandaPool: TRADE_BELOW_MIN");

        fee = deltaBaseReserve.mulDiv(poolFees.sellFee, PandaMath.FEE_SCALE, Math.Rounding.Up);
        amountOut = deltaBaseReserve-fee;
    }

    //Buy = swap baseToken for pandaToken
    //@param amountOut: how much pandaToken user wants
    //@return amountIn: how much baseToken they need to send
    function getAmountInBuy(uint256 amountOut) notGraduated public view returns (uint256 amountIn, uint256 fee, uint256 sqrtP_new) {
        require(amountOut <= pandaReserve, "PandaPool: INSUFFICIENT_LIQUIDITY");
        uint256 pandaReserve_new = pandaReserve - amountOut;
        sqrtP_new = liquidity.mulDiv(sqrtPb, (pandaReserve_new * sqrtPb + liquidity), Math.Rounding.Up);

        if(sqrtP_new > sqrtPb) sqrtP_new = sqrtPb;

        uint256 baseReserve_new = liquidity.mulDiv(sqrtP_new - sqrtPa, PandaMath.PRICE_SCALE, Math.Rounding.Up);
        uint256 deltaBaseReserve = baseReserve_new - baseReserve;

        fee = deltaBaseReserve.mulDiv(poolFees.buyFee, PandaMath.FEE_SCALE -poolFees.buyFee, Math.Rounding.Up);
        amountIn = deltaBaseReserve + fee;
        require(amountIn + 1 gwei >= minTradeSize, "PandaPool: TRADE_BELOW_MIN");
    }

    //Sell = swap pandaToken for baseToken
    //@param amountOut: how much baseToken user wants
    //@return amountIn: how much pandaToken they need to send
    function getAmountInSell(uint256 amountOut) notGraduated public view returns (uint256 amountIn, uint256 fee, uint256 sqrtP_new) {
        fee = amountOut.mulDiv(poolFees.sellFee, PandaMath.FEE_SCALE -poolFees.sellFee, Math.Rounding.Up);
        uint256 deltaBaseReserve = amountOut + fee;

        require(deltaBaseReserve + 1 gwei >= minTradeSize, "PandaPool: TRADE_BELOW_MIN");
        require(deltaBaseReserve <= baseReserve, "PandaPool: INSUFFICIENT_LIQUIDITY");
        uint256 baseReserve_new = baseReserve - deltaBaseReserve;
        sqrtP_new = sqrtPa + baseReserve_new.mulDiv(PandaMath.PRICE_SCALE, liquidity, Math.Rounding.Down);

        if(sqrtP_new < sqrtPa) sqrtP_new = sqrtPa;

        uint256 pandaReserve_new = liquidity.mulDiv(sqrtPb - sqrtP_new, sqrtP_new * sqrtPb, Math.Rounding.Up);
        amountIn = pandaReserve_new - pandaReserve;
    }

    //Get remaining tokens in pool = pandaReserve
    function remainingTokensInPool() public view returns (uint256) {
        return pandaReserve;
    }

    //(Independently calculated) amountIn to buy all remaining tokens in the pool
    function getAmountInBuyRemainingTokens() public view returns (uint256 amountIn) {
        uint256 baseNeeded = totalRaise - baseReserve;
        amountIn = baseNeeded.mulDiv(PandaMath.FEE_SCALE + poolFees.buyFee, PandaMath.FEE_SCALE, Math.Rounding.Up);
    }

    function getTotalRaise() public view returns (uint256) {
        require(initialized, "PandaPool: NOT_INITIALIZED");
        return PandaMath.getTotalRaise(sqrtPa, sqrtPb, tokensInPool);
    }

    //********************************************************************************

    //Get claimable tokens after graduation, when vesting is on.
    //When vesting is off, tokens are transferred directly to the user
    //Function can possibly overriden with more advanced vesting logic
    function claimableTokens(address user) public view virtual returns (uint256) {
        require(vestingPeriod != 0, "PandaPool: VESTING_OFF");
        require(graduated, "PandaPool: NOT_GRADUATED");
        uint256 totalBought = tokensBoughtInPool[user];
        uint256 timeElapsed = block.timestamp - graduationTime;
        uint256 available;
        if(timeElapsed >= vestingPeriod) {
            available = totalBought;
        } else {
            available = totalBought * timeElapsed / vestingPeriod;
        }
        return available - tokensClaimed[user];
    }

    //When vesting is off, tokens are transferred directly to the user
    //Claim vested tokens, only valid when vesting is on.
    function claimTokens(address user) external nonReentrant returns (uint256) {
        require(vestingPeriod != 0, "PandaPool: VESTING_OFF");
        uint256 claimable = claimableTokens(user);
        require(claimable > 0, "PandaPool: NO_CLAIMABLE");
        tokensClaimed[user] += claimable;
        TransferHelper.safeTransfer(pandaToken, user, claimable);
        emit TokensClaimed(user, claimable);
        return claimable;
    }

    //View balance excess of reserves, if any (shouldn't be unless donated to the contract)
    function viewExcessTokens() public view returns (uint256 excessPandaTokens, uint256 excessBaseTokens) {
        excessPandaTokens = IERC20(pandaToken).balanceOf(address(this)) - pandaReserve - tokensForLp;
        excessBaseTokens = IERC20(baseToken).balanceOf(address(this)) - baseReserve;
    }

    //Skim excess to treasury. Anyone can call
    function collectExcessTokens() external nonReentrant {
        (uint256 excessPandaTokens, uint256 excessBaseTokens) = viewExcessTokens();
        TransferHelper.safeTransfer(pandaToken, treasury, excessPandaTokens);
        TransferHelper.safeTransfer(baseToken, treasury, excessBaseTokens);
        emit ExcessCollected(excessPandaTokens, excessBaseTokens);
    }

    //Total balance including unvested tokens (front-end friendly)
    function totalBalanceOf(address user) external view returns (uint256) {
        if(vestingPeriod == 0) {
            return IERC20(pandaToken).balanceOf(user);
        } else {
            return IERC20(pandaToken).balanceOf(user) + tokensBoughtInPool[user] - tokensClaimed[user];
        }
    }

    //Claimable / vested balance (front-end friendly)
    function vestedBalanceOf(address user) external view returns (uint256) {
        if(vestingPeriod == 0) {
            return IERC20(pandaToken).balanceOf(user);
        } else {
            return IERC20(pandaToken).balanceOf(user) + claimableTokens(user);
        }
    }

    //Fallback function to handle sellTokensToBera
    receive() external payable {
        require(wbera == baseToken && msg.sender == wbera, "PandaPool: NOT_BERA_PAIR");
    }

    event PoolInitialized(address pandaToken, address baseToken, uint256 sqrtPa, uint256 sqrtPb, uint256 vestingPeriod, address deployer, bytes data);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
    event Sync(uint256 pandaReserve, uint256 baseReserve, uint256 sqrtPrice);
    event ExcessCollected(uint256 excessPandaTokens, uint256 excessBaseTokens);
    event LiquidityMoved(uint256 amountPanda, uint256 amountBase);
    event TokensClaimed(address indexed user, uint256 amount);
}