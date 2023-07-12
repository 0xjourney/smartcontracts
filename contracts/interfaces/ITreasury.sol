// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ITreasury {
    function registerDailyReward(uint256) external;

    function registerWeeklyReward(uint256) external;

    function addToSeasonalPot(uint256) external;

    function addToTreasury(uint256) external;
}
