## Contracts
| Contract Name          | Address                                    |
| ---------------------- | ------------------------------------------ |
| UniswapV3Factory       | 0xD84CBf0B02636E7f53dB9E5e45A616E05d710990 |
| SwapRouter             | 0xEd158C4b336A6FCb5B193A5570e3a571f6cbe690 |
| SwapRouter02           | 0xe301E48F77963D3F7DbD2a4796962Bd7f3867Fb4 |
| QuoterV2               | 0x644C8D6E501f7C994B74F5ceA96abe65d0BA662B |
| MixedRouteQuoterV1     | 0xfa0276F06161cC2f66Aa51f3500484EdF8Fc94bB |
| TickLens               | 0xa73C6F1FeC76D5487dC30bdB8f11d1F390394b48 |
| KodiakIslandFactory    | 0x5261c5A5f08818c08Ed0Eb036d9575bA1E02c1d6 |
| IslandRouter           | 0x679a7C63FC83b6A4D9C1F931891d705483d4791F |
| KodiakIslandWithRouter | 0xCFe9Ee61c271fBA4D190498b5A71B8CB365a3590 |
| FarmFactory            | 0xAeAa563d9110f833FA3fb1FF9a35DFBa11B0c9cF |
| KodiakFarm             | 0xEB81a9EEAF156d4Cfec2AF364aF36Ad65cF9f0fa |
| XKodiakToken           | 0xe8D7b965BA082835EA917F2B173Ff3E035B69eeB |
| PandaFactory           | 0xac335fe675699b0ce4c927bdaa572eb647ed9f02 |
| RewardVault            | 0x45325Df4A6A6ebD268f4693474AaAa1f3f0ce8Ca |
| ERC1967Proxy           | 0x94ad6ac84f6c6fba8b8ccbd71d9f4f101def52a8 |
| RewardVaultFactory     | 0xc7d78aa74a88d909ba73c783e197e6c4552f3e51 |
| PandaToken             | 0x33D8D074f08F232bA5dc09e0339BD62B1cDDf5f9 |
| UniswapV3Pool          | 0x36815beB3494c6ad3A33540cC242d0B563fe91C0 |


## Permission
| Contract         | Function              | Impact | Owner |
| ---------------- | --------------------- | ------ | ----- |
| UniswapV3Factory | setOwner              | ...    | []    |
| UniswapV3Factory | setDefaultFeeProtocol | ...    | []    |
| UniswapV3Factory | enableFeeAmount       | ...    | []    |

| SwapRouter             | selfPermitIfNecessary                                     | ...    | []                                                     |
| SwapRouter             | selfPermitAllowedIfNecessary                              | ...    | []                                                     |
| SwapRouter             | receive                                                   | ...    | []                                                     |
| SwapRouter             | uniswapV3SwapCallback                                     | ...    | []                                                     |
| SwapRouter             | exactInputSingle                                          | ...    | ['checkDeadline']                                      |
| SwapRouter             | exactInput                                                | ...    | ['checkDeadline']                                      |
| SwapRouter             | exactOutputSingle                                         | ...    | ['checkDeadline']                                      |
| SwapRouter             | exactOutput                                               | ...    | ['checkDeadline']                                      |
| SwapRouter02           | selfPermitIfNecessary                                     | ...    | []                                                     |
| SwapRouter02           | selfPermitAllowedIfNecessary                              | ...    | []                                                     |
| SwapRouter02           | multicall                                                 | ...    | ['checkDeadline']                                      |
| SwapRouter02           | multicall                                                 | ...    | ['checkPreviousBlockhash']                             |
| SwapRouter02           | uniswapV3SwapCallback                                     | ...    | []                                                     |
| SwapRouter02           | receive                                                   | ...    | []                                                     |
| UniswapV2Router02      | receive                                                   | ...    | []                                                     |
| UniswapV2Router02      | addLiquidity                                              | ...    | ['ensure']                                             |
| UniswapV2Router02      | addLiquidityETH                                           | ...    | ['ensure']                                             |
| UniswapV2Router02      | removeLiquidity                                           | ...    | ['ensure']                                             |
| UniswapV2Router02      | removeLiquidityETH                                        | ...    | ['ensure']                                             |
| UniswapV2Router02      | removeLiquidityWithPermit                                 | ...    | ['ensure']                                             |
| UniswapV2Router02      | removeLiquidityETHWithPermit                              | ...    | ['ensure']                                             |
| UniswapV2Router02      | removeLiquidityETHSupportingFeeOnTransferTokens           | ...    | ['ensure']                                             |
| UniswapV2Router02      | removeLiquidityETHWithPermitSupportingFeeOnTransferTokens | ...    | ['ensure']                                             |
| UniswapV2Router02      | swapExactTokensForTokens                                  | ...    | ['ensure']                                             |
| UniswapV2Router02      | swapTokensForExactTokens                                  | ...    | ['ensure']                                             |
| UniswapV2Router02      | swapExactETHForTokens                                     | ...    | ['ensure']                                             |
| UniswapV2Router02      | swapTokensForExactETH                                     | ...    | ['ensure']                                             |
| UniswapV2Router02      | swapExactTokensForETH                                     | ...    | ['ensure']                                             |
| UniswapV2Router02      | swapETHForExactTokens                                     | ...    | ['ensure']                                             |
| UniswapV2Router02      | swapExactTokensForTokensSupportingFeeOnTransferTokens     | ...    | ['ensure']                                             |
| UniswapV2Router02      | swapExactETHForTokensSupportingFeeOnTransferTokens        | ...    | ['ensure']                                             |
| UniswapV2Router02      | swapExactTokensForETHSupportingFeeOnTransferTokens        | ...    | ['ensure']                                             |
| QuoterV2               | uniswapV3SwapCallback                                     | ...    | []                                                     |


| MixedRouteQuoterV1     | uniswapV3SwapCallback                                     | ...    | []                                                     |
| KodiakIslandFactory    | renounceOwnership                                         | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakIslandFactory    | transferOwnership                                         | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakIslandFactory    | setIslandImplementation                                   | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakIslandFactory    | setTreasury                                               | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakIslandFactory    | setIslandFee                                              | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakIslandWithRouter | uniswapV3MintCallback                                     | ...    | []                                                     |
| KodiakIslandWithRouter | uniswapV3SwapCallback                                     | ...    | []                                                     |
| KodiakIslandWithRouter | mint                                                      | ...    | ['nonReentrant', 'whenNotPaused']                      |
| KodiakIslandWithRouter | burn                                                      | ...    | ['nonReentrant', 'whenNotPaused']                      |
| KodiakIslandWithRouter | executiveRebalance                                        | ...    | ['onlyManager', 'whenNotPaused']                       |
| KodiakIslandWithRouter | rebalance                                                 | ...    | ['whenNotPaused']                                      |
| KodiakIslandWithRouter | updateManagerParams                                       | ...    | ['onlyManager']                                        |
| KodiakIslandWithRouter | setRestrictedMint                                         | ...    | ['onlyManager']                                        |
| KodiakIslandWithRouter | pause                                                     | ...    | ['onlyPauserOrAbove', 'whenNotPaused']                 |
| KodiakIslandWithRouter | unpause                                                   | ...    | ['onlyManager', 'whenPaused']                          |
| KodiakIslandWithRouter | setPauser                                                 | ...    | ['onlyManager']                                        |
| KodiakIslandWithRouter | renounceOwnership                                         | ...    | ['onlyManager', 'whenNotPaused']                       |
| KodiakIslandWithRouter | _pause                                                    | ...    | ['whenNotPaused']                                      |
| KodiakIslandWithRouter | _unpause                                                  | ...    | ['whenPaused']                                         |
| KodiakIslandWithRouter | transferOwnership                                         | ...    | ['onlyManager']                                        |
| KodiakIslandWithRouter | transferFrom                                              | ...    | []                                                     |
| KodiakIslandWithRouter | setRouter                                                 | ...    | ['onlyManager']                                        |
| KodiakIslandWithRouter | executiveRebalanceWithRouter                              | ...    | ['onlyManager', 'whenNotPaused']                       |
| FarmFactory            | renounceOwnership                                         | ...    | 0x0000000000000000000000000000000000000000             |
| FarmFactory            | transferOwnership                                         | ...    | 0x0000000000000000000000000000000000000000             |
| FarmFactory            | setXKdk                                                   | ...    | 0x0000000000000000000000000000000000000000             |
| FarmFactory            | setAllowedImplementation                                  | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakFarm             | renounceOwnership                                         | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakFarm             | transferOwnership                                         | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakFarm             | initialize                                                | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakFarm             | startFarm                                                 | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakFarm             | stakeLocked                                               | ...    | ['nonReentrant', 'updateRewardAndBalance']             |
| KodiakFarm             | _stakeLocked                                              | ...    | ['updateRewardAndBalance']                             |
| KodiakFarm             | withdrawLocked                                            | ...    | ['nonReentrant', 'updateRewardAndBalance']             |
| KodiakFarm             | withdrawLockedMultiple                                    | ...    | ['nonReentrant', 'updateRewardAndBalance']             |
| KodiakFarm             | withdrawLockedAll                                         | ...    | ['nonReentrant', 'updateRewardAndBalance']             |
| KodiakFarm             | emergencyWithdraw                                         | ...    | ['nonReentrant', 'updateRewardAndBalance']             |
| KodiakFarm             | _withdrawLocked                                           | ...    | ['updateRewardAndBalance']                             |
| KodiakFarm             | getReward                                                 | ...    | ['nonReentrant', 'updateRewardAndBalance']             |
| KodiakFarm             | _getReward                                                | ...    | ['updateRewardAndBalance']                             |
| KodiakFarm             | recoverERC20                                              | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakFarm             | setRewardsDuration                                        | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakFarm             | setMultipliers                                            | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakFarm             | setLockedStakeTimeForMinAndMaxMultiplier                  | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakFarm             | setGreylist                                               | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakFarm             | setStakesUnlocked                                         | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakFarm             | setStakingPaused                                          | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakFarm             | setRewardsCollectionPaused                                | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakFarm             | setRewardRate                                             | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakFarm             | changeTokenManager                                        | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakFarm             | addNewRewardToken                                         | ...    | 0x0000000000000000000000000000000000000000             |
| KodiakFarm             | setStakingTokenCap                                        | ...    | 0x0000000000000000000000000000000000000000             |
| XKodiakToken           | renounceOwnership                                         | ...    | 0x0000000000000000000000000000000000000000             |
| XKodiakToken           | transferOwnership                                         | ...    | 0x0000000000000000000000000000000000000000             |
| XKodiakToken           | getUserRedeem                                             | ...    | ['validateRedeem']                                     |
| XKodiakToken           | setKdkAddress                                             | ...    | 0x0000000000000000000000000000000000000000             |
| XKodiakToken           | mint                                                      | ...    | 0x0000000000000000000000000000000000000000             |
| XKodiakToken           | updateRedeemSettings                                      | ...    | 0x0000000000000000000000000000000000000000             |
| XKodiakToken           | updateRewardsAddress                                      | ...    | 0x0000000000000000000000000000000000000000             |
| XKodiakToken           | updateDeallocationFee                                     | ...    | 0x0000000000000000000000000000000000000000             |
| XKodiakToken           | updateWhitelister                                         | ...    | 0x0000000000000000000000000000000000000000             |
| XKodiakToken           | updateTransferWhitelist                                   | ...    | 0x0000000000000000000000000000000000000000             |
| XKodiakToken           | setBurnAddress                                            | ...    | 0x0000000000000000000000000000000000000000             |
| XKodiakToken           | approveUsage                                              | ...    | ['kdkActive', 'nonReentrant']                          |
| XKodiakToken           | convert                                                   | ...    | ['kdkActive', 'nonReentrant']                          |
| XKodiakToken           | convertTo                                                 | ...    | ['kdkActive', 'nonReentrant']                          |
| XKodiakToken           | redeem                                                    | ...    | ['kdkActive', 'nonReentrant']                          |
| XKodiakToken           | finalizeRedeem                                            | ...    | ['kdkActive', 'nonReentrant', 'validateRedeem']        |
| XKodiakToken           | updateRedeemRewardsAddress                                | ...    | ['kdkActive', 'nonReentrant', 'validateRedeem']        |
| XKodiakToken           | cancelRedeem                                              | ...    | ['kdkActive', 'nonReentrant', 'validateRedeem']        |
| XKodiakToken           | allocate                                                  | ...    | ['kdkActive', 'nonReentrant']                          |
| XKodiakToken           | allocateFromUsage                                         | ...    | ['kdkActive', 'nonReentrant']                          |
| XKodiakToken           | deallocate                                                | ...    | ['kdkActive', 'nonReentrant']                          |
| XKodiakToken           | deallocateFromUsage                                       | ...    | ['kdkActive', 'nonReentrant']                          |
| PandaFactory           | renounceOwnership                                         | ...    | 0x0000000000000000000000000000000000000000             |
| PandaFactory           | transferOwnership                                         | ...    | 0x0000000000000000000000000000000000000000             |
| PandaFactory           | deployPandaToken                                          | ...    | ['nonReentrant']                                       |
| PandaFactory           | deployPandaTokenWithBera                                  | ...    | ['nonReentrant']                                       |
| PandaFactory           | deployPandaPool                                           | ...    | ['nonReentrant']                                       |
| PandaFactory           | claimIncentive                                            | ...    | ['nonReentrant']                                       |
| PandaFactory           | setMinRaise                                               | ...    | 0x0000000000000000000000000000000000000000             |
| PandaFactory           | setMinTradeSize                                           | ...    | 0x0000000000000000000000000000000000000000             |
| PandaFactory           | setTreasury                                               | ...    | 0x0000000000000000000000000000000000000000             |
| PandaFactory           | setDexFactory                                             | ...    | 0x0000000000000000000000000000000000000000             |
| PandaFactory           | setAllowedImplementation                                  | ...    | 0x0000000000000000000000000000000000000000             |
| PandaFactory           | setWbera                                                  | ...    | 0x0000000000000000000000000000000000000000             |
| PandaFactory           | setIncentive                                              | ...    | 0x0000000000000000000000000000000000000000             |
| PandaFactory           | setPandaPoolFees                                          | ...    | 0x0000000000000000000000000000000000000000             |

| RewardVault            | setDistributor                                            | ...    | ['onlyFactoryOwner']                                   |
| RewardVault            | notifyRewardAmount                                        | ...    | ['onlyDistributor', 'updateReward']                    |
| RewardVault            | recoverERC20                                              | ...    | ['onlyFactoryOwner']                                   |
| RewardVault            | setRewardsDuration                                        | ...    | ['onlyFactoryOwner']                                   |
| RewardVault            | whitelistIncentiveToken                                   | ...    | ['onlyFactoryOwner']                                   |
| RewardVault            | removeIncentiveToken                                      | ...    | ['onlyFactoryVaultManager', 'onlyWhitelistedToken']    |
| RewardVault            | updateIncentiveManager                                    | ...    | ['onlyFactoryOwner', 'onlyWhitelistedToken']           |
| RewardVault            | setMaxIncentiveTokensCount                                | ...    | ['onlyFactoryOwner']                                   |
| RewardVault            | pause                                                     | ...    | ['onlyFactoryVaultPauser', 'whenNotPaused']            |
| RewardVault            | unpause                                                   | ...    | ['onlyFactoryVaultManager', 'whenPaused']              |
| RewardVault            | stake                                                     | ...    | ['nonReentrant', 'whenNotPaused']                      |
| RewardVault            | delegateStake                                             | ...    | ['nonReentrant', 'whenNotPaused']                      |
| RewardVault            | withdraw                                                  | ...    | ['checkSelfStakedBalance', 'nonReentrant']             |
| RewardVault            | delegateWithdraw                                          | ...    | ['nonReentrant']                                       |
| RewardVault            | getReward                                                 | ...    | ['nonReentrant', 'onlyOperatorOrUser', 'updateReward'] |
| RewardVault            | exit                                                      | ...    | ['nonReentrant', 'updateReward']                       |
| RewardVault            | addIncentive                                              | ...    | ['nonReentrant', 'onlyWhitelistedToken']               |
| RewardVault            | accountIncentives                                         | ...    | ['nonReentrant', 'onlyWhitelistedToken']               |

| RewardVaultFactory     | proxiableUUID                                             | ...    | ['notDelegated']                                       |
| RewardVaultFactory     | upgradeToAndCall                                          | ...    | ['onlyProxy', 'onlyRole']                              |
| RewardVaultFactory     | grantRole                                                 | ...    | ['getRoleAdmin', 'onlyRole']                           |
| RewardVaultFactory     | revokeRole                                                | ...    | ['getRoleAdmin', 'onlyRole']                           |
| RewardVaultFactory     | initialize                                                | ...    | ['initializer', 'onlyInitializing']                    |
| RewardVaultFactory     | setBGTIncentiveDistributor                                | ...    | ['onlyRole']                                           |

| PandaToken             | moveLiquidity                                             | ...    | ['nonReentrant']                                       |
| PandaToken             | buyTokensWithBera                                         | ...    | ['nonReentrant', 'notGraduated', 'onlyBeraPair']       |
| PandaToken             | buyTokens                                                 | ...    | ['nonReentrant', 'notGraduated']                       |
| PandaToken             | buyTokens                                                 | ...    | ['nonReentrant', 'notGraduated']                       |
| PandaToken             | buyAllTokens                                              | ...    | ['nonReentrant', 'notGraduated']                       |
| PandaToken             | sellTokensForBera                                         | ...    | ['nonReentrant', 'notGraduated', 'onlyBeraPair']       |
| PandaToken             | sellTokens                                                | ...    | ['nonReentrant', 'notGraduated']                       |
| PandaToken             | sellTokens                                                | ...    | ['nonReentrant', 'notGraduated']                       |
| PandaToken             | getAmountOutBuy                                           | ...    | ['notGraduated']                                       |
| PandaToken             | getAmountOutSell                                          | ...    | ['notGraduated']                                       |
| PandaToken             | getAmountInBuy                                            | ...    | ['notGraduated']                                       |
| PandaToken             | getAmountInSell                                           | ...    | ['notGraduated']                                       |
| PandaToken             | claimTokens                                               | ...    | ['nonReentrant']                                       |
| PandaToken             | collectExcessTokens                                       | ...    | ['nonReentrant']                                       |
| PandaToken             | receive                                                   | ...    | []                                                     |

| UniswapV3Pool          | increaseObservationCardinalityNext                        | ...    | ['lock']                                               |
| UniswapV3Pool          | mint                                                      | ...    | ['lock']                                               |
| UniswapV3Pool          | collect                                                   | ...    | ['lock']                                               |
| UniswapV3Pool          | burn                                                      | ...    | ['lock']                                               |
| UniswapV3Pool          | flash                                                     | ...    | ['lock']                                               |
| UniswapV3Pool          | setFeeProtocol                                            | ...    | ['lock', 'onlyFactoryOwner']                           |
| UniswapV3Pool          | collectProtocol                                           | ...    | ['lock', 'onlyFactoryOwner']                           |
