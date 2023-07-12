// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./Staking.sol";
import "../interfaces/IHnP.sol";
import "../interfaces/INFTRegistry.sol";

contract MountainPass is Staking, ERC721 {
    INFTRegistry public nftRegistry;
    address public immutable treasury;

    uint256 public mintPrice = 1 ether / 2;
    uint256 public counter = 1;

    constructor(
        address _journey,
        address _progress,
        address _nftRegistry,
        address _treasury
    )
        ERC721("Mountain Pass", "MTNPS")
        Staking(_journey, _progress, 50000000, (25 ether) / 10**7, 0)
    {
        nftRegistry = INFTRegistry(_nftRegistry);
        treasury = _treasury;
    }

    function mint() external payable {
        require(balanceOf(msg.sender) == 0, "you may only own 1 bundle");
        require(msg.value >= mintPrice, "moar pls");
        if (msg.value > mintPrice) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - mintPrice);
        }
        TransferHelper.safeTransferETH(treasury, mintPrice);
        _mint(msg.sender, counter);
        nftRegistry.registerNewNFT(msg.sender, counter);
        counter += 1;
    }

    /**
     * @notice bundles may not be transfered
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(false, "bundles may not be transferred");
    }
}
