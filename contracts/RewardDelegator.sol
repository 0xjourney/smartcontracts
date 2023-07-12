// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ITaxHelper.sol";
import "./interfaces/ITreasury.sol";

/**
 * @dev This smartcontract acts as an intermediary between the $Journey token and the Treasury. It collects
 * and delegates the appropriate rewards to the appropriate pools. Since this SmartContract can be swapped out
 * for any new Delegator, $Journey will be able to support any new type of reward system in the future.
 */
contract RewardDelegator is ITaxHelper {
    ITreasury public immutable treasury;
    IERC20 public immutable journey;

    constructor(address _treasury, address _journey) {
        treasury = ITreasury(_treasury);
        journey = IERC20(_journey);
        IERC20(_journey).approve(_treasury, type(uint256).max);
    }

    // ▸ Weekly rewards: 1% (in tokens)
    // ▸ Season rewards: 2% (in USDC)
    // ▸ Development: 2% (in USDC)
    // ▸ Marketing: 1% (in USDC)
    // ▸ Ecosystem: 1% (in tokens)
    // ▸ Sherpa: 1% (in tokens)
    function handleTax(uint256 _amount) external {
        //
        uint256 sherpaReward = _amount / 8;
        uint256 seasonRewards = (_amount / 8) * 2;
        uint256 weeklyRewards = _amount / 8;
        uint256 theRest = _amount -
            sherpaReward -
            seasonRewards -
            weeklyRewards;

        treasury.registerDailyReward(sherpaReward);
        treasury.addToSeasonalPot(seasonRewards);
        treasury.registerWeeklyReward(weeklyRewards);
        treasury.addToTreasury(theRest);
    }
}
