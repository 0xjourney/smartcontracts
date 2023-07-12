// // SPDX-License-Identifier: UNLICENSED

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// import "interfaces/IProgress.sol";

// abstract contract Powerup {
//     using EnumerableSet for EnumerableSet.AddressSet;
//     using EnumerableSet for EnumerableSet.UintSet;

//     IProgress public immutable progressRegistry;

//     constructor(address _progressRegistry) public {
//         progress = IProgress(_progressRegistry);
//     }

//     // called by NFT
//     function beerMe(uint256 _mps) internal virtual {
//         progress.updatePlayerMeters(msg.sender, _mps, true);
//     }
// }
