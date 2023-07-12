// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IHnP {
    function rekPlayer(
        address _target,
        address _deployer,
        uint256 _meterPenalty,
        uint256 _duration,
        uint256 _nftID,
        uint256 _nftType
    ) external;
}
