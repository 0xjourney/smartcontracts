// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../external/libraries/TransferHelper.sol";

import "../interfaces/IERC721Extended.sol";
import "./Handicap.sol";
import "../interfaces/IHnP.sol";

contract Avalanche is Handicap, ERC721 {
    uint256 public counter;
    uint256 public mintPrice = 2 ether;

    IERC721Extended public immutable basic;
    IERC721Extended public immutable shiny;
    address public immutable treasury;
    address private priceAdmin;

    modifier onlyTreasury() {
        require(msg.sender == treasury, "forbiddin");
        _;
    }

    constructor(
        address _hnp,
        address _nftRegistry,
        address _treasury,
        address _basic,
        address _shiny
    )
        ERC721("Avalanche", "AVLCH")
        Handicap(_hnp, _nftRegistry, 26 hours, 1000 * 10**9, 3)
    {
        priceAdmin = msg.sender;
        treasury = _treasury;
        basic = IERC721Extended(_basic);
        shiny = IERC721Extended(_shiny);
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

    function mint(bool _basic, uint256 _id) external payable {
        require(msg.value >= mintPrice, "moar pls");
        if (msg.value > mintPrice) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - mintPrice);
        }
        TransferHelper.safeTransferETH(treasury, mintPrice);
        if (_basic) {
            require(basic.ownerOf(_id) == msg.sender, "u no own");
            basic.burn(_id);
        } else {
            require(shiny.ownerOf(_id) == msg.sender, "u no own");
            shiny.burn(_id);
        }
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
