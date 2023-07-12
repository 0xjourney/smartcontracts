// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../external/libraries/TransferHelper.sol";

import "./Handicap.sol";
import "../interfaces/IHnP.sol";

contract Yeti is Handicap, ERC721 {
    uint256 public counter;
    uint256 public mintPrice = 1 ether;

    address public immutable treasury;
    address private priceAdmin;

    modifier onlyTreasury() {
        require(msg.sender == treasury, "forbiddin");
        _;
    }

    constructor(
        address _hnp,
        address _nftRegistry,
        address _treasury
    )
        ERC721("Yeti", "YTI")
        Handicap(_hnp, _nftRegistry, 12 hours, 200 * 10**9, 1)
    {
        priceAdmin = msg.sender;
        treasury = _treasury;
    }

    function updateMintPrice(uint256 _newPrice) external {
        require(msg.sender == priceAdmin, "bruh");
        mintPrice = _newPrice;
    }

    function freeMint(address _to) external onlyTreasury {
        _mint(_to, counter);
        nftRegistry.registerNewNFT(msg.sender, counter);
        counter += 1;
    }

    function mint() external payable {
        require(msg.value >= mintPrice, "moar pls");
        if (msg.value > mintPrice) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - mintPrice);
        }
        TransferHelper.safeTransferETH(treasury, mintPrice);
        _mint(msg.sender, counter);
        nftRegistry.registerNewNFT(msg.sender, counter);
        counter += 1;
    }

    function deployHandicap(address _target, uint256 _id) external {
        require(msg.sender != _target, "cannot target self");
        require(ownerOf(_id) == msg.sender, "thou dost not owneth this");
        registerHandicap(_target, msg.sender, _id);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        nftRegistry.registerNFTTransfer(from, to, tokenId);
    }
}
