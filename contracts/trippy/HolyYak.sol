// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
/*
 *
 *    ▄█    █▄     ▄██████▄   ▄█       ▄██   ▄        ▄██   ▄      ▄████████    ▄█   ▄█▄
 *   ███    ███   ███    ███ ███       ███   ██▄      ███   ██▄   ███    ███   ███ ▄███▀
 *   ███    ███   ███    ███ ███       ███▄▄▄███      ███▄▄▄███   ███    ███   ███▐██▀
 *  ▄███▄▄▄▄███▄▄ ███    ███ ███       ▀▀▀▀▀▀███      ▀▀▀▀▀▀███   ███    ███  ▄█████▀
 * ▀▀███▀▀▀▀███▀  ███    ███ ███       ▄██   ███      ▄██   ███ ▀███████████ ▀▀█████▄
 *   ███    ███   ███    ███ ███       ███   ███      ███   ███   ███    ███   ███▐██▄
 *   ███    ███   ███    ███ ███▌    ▄ ███   ███      ███   ███   ███    ███   ███ ▀███▄
 *   ███    █▀     ▀██████▀  █████▄▄██  ▀█████▀        ▀█████▀    ███    █▀    ███   ▀█▀
 *                           ▀                                                 ▀
 *
 * This powerup is holy, and also it's a yak. Use with care, and please for the love of God do not overdose.
 */

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../interfaces/INFTRegistry.sol";

contract HolyYak is ERC721 {
    uint256 public constant price = 1 ether / 10;
    uint256 public counter = 1;

    mapping(uint256 => bool) public deployed;
    mapping(address => uint256) public trippyTimer;

    INFTRegistry public nftRegistry;

    constructor(address _nftRegistry) ERC721("Holy Yak", "HLYK") {
        nftRegistry = INFTRegistry(_nftRegistry);
    }

    function mint() external {
        _mint(msg.sender, counter);
        nftRegistry.registerNewNFT(msg.sender, counter);
        counter += 1;
    }

    function randomMint() external payable {
        // get signed txn data and verify for 'random' events on user screen
    }

    function deploy(uint256 _nftID) external {
        require(ownerOf(_nftID) == msg.sender, "you no own dis");
        deployed[_nftID] = true;
        trippyTimer[msg.sender] += block.timestamp + 24 hours;
    }

    function userTripDuration(address _user) external view returns (uint256) {
        uint256 userLowStart = trippyTimer[_user];
        return
            block.timestamp < userLowStart ? userLowStart - block.timestamp : 0;
    }
}
