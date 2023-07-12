// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../interfaces/IProgress.sol";
import "../interfaces/IJourneyBackpack.sol";

contract FreeBackpackMinter {
    IJourneyBackpack public immutable basic;
    IJourneyBackpack public immutable shiny;
    IProgress public immutable progress;

    constructor(
        address _basic,
        address _shiny,
        address _progress
    ) {
        basic = IJourneyBackpack(_basic);
        shiny = IJourneyBackpack(_shiny);
        progress = IProgress(_progress);
    }

    function mintFreeBackpack() external {
        require(progress.isPlayerEligibleForFreeBackpack(msg.sender), "no");
        uint256 random = uint256(
            keccak256(
                bytes.concat(
                    abi.encodePacked(progress.getPlayerMeters(msg.sender)),
                    abi.encodePacked(msg.sender),
                    abi.encodePacked(block.timestamp)
                )
            )
        ) % 100;
        if (random >= 80) {
            shiny.mintTo(msg.sender);
        } else {
            basic.mintTo(msg.sender);
        }
    }
}
