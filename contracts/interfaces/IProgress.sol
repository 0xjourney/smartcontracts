// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IProgress {
    function getPlayerMPS(address) external view returns (uint256);

    function getPlayerMeters(address) external view returns (uint256);

    function updatePlayerMeters(address, uint256) external;

    function updatePlayerMetersPerSecond(address, uint256) external;

    function isPlayerEligibleForFreeBackpack(address)
        external
        view
        returns (bool);
}
