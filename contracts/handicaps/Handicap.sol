// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../interfaces/IHnP.sol";
import "../interfaces/INFTRegistry.sol";

abstract contract Handicap {
    uint256 public immutable meterStoppageDuration;
    uint256 public immutable meterPenalty;
    uint256 public immutable NFTType;

    mapping(uint256 => bool) public handicapDeployed;
    IHnP public handicapsAndPowerups;
    INFTRegistry public nftRegistry;

    constructor(
        address _hnp,
        address _nftRegistry,
        uint256 _stopDuration,
        uint256 _meterPenalty,
        uint256 _type
    ) {
        NFTType = _type;
        meterStoppageDuration = _stopDuration;
        meterPenalty = _meterPenalty;
        handicapsAndPowerups = IHnP(_hnp);
        nftRegistry = INFTRegistry(_nftRegistry);
    }

    function registerHandicap(
        address _target,
        address _deployer,
        uint256 _nftID
    ) internal {
        require(!handicapDeployed[_nftID], "handicap already deployed");
        handicapsAndPowerups.rekPlayer(
            _target,
            _deployer,
            meterPenalty,
            meterStoppageDuration,
            _nftID,
            NFTType
        );
        handicapDeployed[_nftID] = true;
    }
}
