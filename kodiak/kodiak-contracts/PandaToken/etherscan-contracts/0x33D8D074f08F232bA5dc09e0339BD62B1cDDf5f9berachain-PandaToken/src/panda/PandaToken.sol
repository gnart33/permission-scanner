// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {ERC20Permit, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {PandaPool, TransferHelper, IERC20} from "src/panda/PandaPool.sol";
import {PandaMath} from "src/libraries/PandaMath.sol";
import "src/interfaces/IV2Pair.sol";
import "src/interfaces/IV2Factory.sol";

contract PandaToken is ERC20Permit, PandaPool {
    using Math for uint256;

    address public dexFactory;
    address public dexPair;

    string private _name;
    string private _symbol;

    function VERSION() external pure virtual override returns (string memory) {
        return "PandaTokenV1";
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    constructor() ERC20Permit("PandaToken") ERC20("PandaToken", "PT") PandaPool() {}

    function _beforeInitializePool(bytes calldata data) internal override {
        _mint(address(this), pandaFactory.TOKEN_SUPPLY());
        (_name, _symbol) = abi.decode(data, (string, string));
    }

    function _afterInitializePool(bytes calldata /*data*/) internal override {
        require(vestingPeriod == 0, "PandaToken: VESTING_NONZERO"); //We don't allow vesting in the standard PandaToken
        require(totalTokens == pandaFactory.TOKEN_SUPPLY(), "PandaToken: INVALID_SUPPLY"); //Has to use default total supply
        dexFactory = pandaFactory.dexFactory();
        dexPair = PandaMath.getDexPair(address(this), baseToken, dexFactory, pandaFactory.initCodeHash());
    }

    function _moveLiquidity() internal override {
        address _pandaToken = pandaToken;
        address _baseToken = baseToken;

        IV2Factory _dexFactory = IV2Factory(dexFactory);
        uint256 graduationFeeInBaseTokens = baseReserve * poolFees.graduationFee / PandaMath.FEE_SCALE;

        uint256 amountBase = baseReserve - graduationFeeInBaseTokens;

        //PandaTokens added to LP calculated such that the dex price is the same as the price at graduation
        //If exactly 100% of the tokensInPool are sold, amountPanda == tokensForLp and price == sqrtPb**2
        //If slightly less than 100% are sold: tokensForLp <= amountPanda <= tokensForLp+pandaReserve
        uint256 amountPanda = amountBase.mulDiv(PandaMath.PRICE_SCALE, getCurrentPrice(), Math.Rounding.Down);

        //Enforce the bounds discussed
        if(amountPanda > tokensForLp + pandaReserve) {amountPanda = tokensForLp + pandaReserve;}
        if(amountPanda < tokensForLp) {amountPanda = tokensForLp;}

        //Create pair if necessary
        address pair = _dexFactory.getPair(_pandaToken, _baseToken);
        if(pair == address(0)) {
            pair = _dexFactory.createPair(_pandaToken, _baseToken);
        }
        require(pair == dexPair, "PandaPool: INVALID_PAIR");

        //mark graduated
        graduated = true;
        graduationTime = block.timestamp;

        TransferHelper.safeTransfer(_pandaToken, pair, amountPanda);
        TransferHelper.safeTransfer(_baseToken, pair, amountBase);
        IV2Pair(pair).mint(DEADADDRESS);
        tokensForLp = 0;

        //Deployer fee share
        uint256 deployerFee = graduationFeeInBaseTokens * poolFees.deployerFeeShare / PandaMath.FEE_SCALE;
        TransferHelper.safeTransfer(_baseToken, deployer, deployerFee);

        //Transfer remaining baseTokens to the treasury
        TransferHelper.safeTransfer(_baseToken, treasury, IERC20(_baseToken).balanceOf(address(this)));

        emit LiquidityMoved(amountPanda, amountBase);
    }

    //transfer blacklist the v2 pool until graduated from PandaPool
    function _beforeTokenTransfer(address /*from*/, address to, uint256 /*amount*/) internal view override {
        require(graduated || to != dexPair, "PandaToken: INVALID_TRANSFER");
    }

    // No approvals needed to trade within the bonding curve
    function allowance(address owner, address spender) public view override returns (uint256) {
        if (spender == address(this)) {
            return type(uint256).max;
        } else {
            return super.allowance(owner, spender);
        }
    }

}