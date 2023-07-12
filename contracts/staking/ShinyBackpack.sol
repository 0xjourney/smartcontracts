// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../external/libraries/TransferHelper.sol";

import "./Staking.sol";
import "../interfaces/IHnP.sol";
import "../interfaces/INFTRegistry.sol";

contract ShinyBackpack is Staking, ERC721 {
    INFTRegistry public nftRegistry;

    address public immutable treasury;
    address private immutable freeBackpackMinter;
    uint256 public counter = 1;
    mapping(uint256 => uint256) public shinyMPS;

    modifier onlyFreeMinter() {
        require(
            msg.sender == freeBackpackMinter,
            "thou shalteth noteth useth thiseth functioneth"
        );
        _;
    }

    modifier onlyTreasury() {
        require(msg.sender == treasury, "only treasury can use this");
        _;
    }

    constructor(
        address _journey,
        address _progress,
        address _nftRegistry,
        address _freeBackpackMinter,
        address _treasury
    )
        ERC721("Shiny Backpack", "SHINY")
        Staking(_journey, _progress, 50000000, 10, 2)
    {
        nftRegistry = INFTRegistry(_nftRegistry);
        treasury = _treasury;
        freeBackpackMinter = _freeBackpackMinter;
    }

    fallback() external payable {
        TransferHelper.safeTransferETH(treasury, msg.value);
    }

    function mint() external onlyTreasury {
        _mint(msg.sender, counter);
        nftRegistry.registerNewNFT(msg.sender, counter);
        counter += 1;
    }

    function mintTo(address _who) external onlyFreeMinter {
        // TODO implement random mps for shiny backpack
        _mint(_who, counter);
        nftRegistry.registerNewNFT(_who, counter);
        counter += 1;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(userStakedBalance(from) == 0, "unstake your tokens first");
        nftRegistry.registerNFTTransfer(from, to, tokenId);
    }
}
