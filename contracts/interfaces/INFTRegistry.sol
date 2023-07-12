// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface INFTRegistry {
    function registerNewNFT(address _owner, uint256 _nftID) external;

    function registerNFTTransfer(
        address _oldOwner,
        address _newOwner,
        uint256 _nftID
    ) external;
}
