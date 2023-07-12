// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IMigrate {
    function migrateToken(
        address _token,
        uint256 _amount,
        bool _weth
    ) external;
}
