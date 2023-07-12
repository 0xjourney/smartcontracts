// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev This smartcontract acts as an inventory for $Journey NFTs. It holds a collection of nft
 * IDs for each registered NFT, tied directly to their owner. The intended use is for the client-side
 * to be able to display the entire player inventory and allow for quick access to NFT ids.
 */
contract NFTRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => mapping(address => EnumerableSet.UintSet))
        private playerNFTs;

    address public owner;
    EnumerableSet.AddressSet private nfts;

    /**
     * @notice ensures that only registered NFTs may call functions
     */
    modifier onlyNFT() {
        require(nfts.contains(msg.sender), "yu no do dis");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice registers a newly minted nft and owner
     */
    function registerNewNFT(address _owner, uint256 _nftID) external onlyNFT {
        playerNFTs[_owner][msg.sender].add(_nftID);
    }

    /**
     * @notice updates registry info with new nft owner, removing the old owner
     */
    function registerNFTTransfer(
        address _oldOwner,
        address _newOwner,
        uint256 _nftID
    ) external onlyNFT {
        playerNFTs[_oldOwner][msg.sender].remove(_nftID);
        playerNFTs[_newOwner][msg.sender].add(_nftID);
    }

    /**
     * @notice adds or removes nft address
     */
    function updateNFTAddresses(address _nft, bool _add) external {
        require(msg.sender == owner, "yu definitely no do dis");
        if (_add) {
            nfts.add(_nft);
        } else {
            nfts.remove(_nft);
        }
    }

    /**
     * @notice returns the number of a specific nft owned by player
     */
    function getPlayerNFTCount(address _player, address _nftType)
        external
        view
        returns (uint256)
    {
        return playerNFTs[_player][_nftType].length();
    }

    /**
     * @notice returns player-owned nft at index
     */
    function getPlayerNFTAtIndex(
        address _player,
        address _nftType,
        uint256 _index
    ) external view returns (uint256) {
        return playerNFTs[_player][_nftType].at(_index);
    }
}
