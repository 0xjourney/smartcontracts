// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../interfaces/IERC721Extended.sol";
import "./Staking.sol";
import "../interfaces/IHnP.sol";
import "../interfaces/INFTRegistry.sol";

contract Sherpa is Staking, ERC721 {
    INFTRegistry public nftRegistry;
    IERC721Extended public immutable basic;
    IERC721Extended public immutable shiny;

    // cost to mint in USD
    address public constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    uint256 public constant mintCost = 1500;
    uint256 public counter = 1;

    constructor(
        address _journey,
        address _progress,
        address _nftRegistry,
        address _basicBackpack,
        address _shinyBackpack
    )
        ERC721("Sherpa", "SHRP")
        Staking(_journey, _progress, 250000000, 1 ether / 10**5, 3)
    {
        basic = IERC721Extended(_basicBackpack);
        shiny = IERC721Extended(_shinyBackpack);
        nftRegistry = INFTRegistry(_nftRegistry);
    }

    function mint(uint256[] calldata _basics, uint256[] calldata _shinys)
        external
        payable
    {
        require(_basics.length + _shinys.length == 5, "must burn exactly 5");
        for (uint256 i = 0; i < _basics.length; i++) {
            require(basic.ownerOf(_basics[i]) == msg.sender, "u no own");
            basic.burn(_basics[i]);
        }
        for (uint256 i = 0; i < _shinys.length; i++) {
            require(shiny.ownerOf(_shinys[i]) == msg.sender, "u no own");
            basic.burn(_shinys[i]);
        }
        // TODO swap X journey for 1500 USD
        journey.transferFrom(msg.sender, DEAD_ADDRESS, mintCost);
        _mint(msg.sender, counter);
        nftRegistry.registerNewNFT(msg.sender, counter);
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
