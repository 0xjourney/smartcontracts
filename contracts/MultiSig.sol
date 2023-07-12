// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev
 */
abstract contract MultiSig {
    mapping(uint256 => mapping(uint256 => uint256)) private votes;
    mapping(uint256 => uint256) private lastCallVote;

    uint256 public redundancy;

    modifier requireQuorum(uint256 _call) {
        votes[_call][lastCallVote[_call]] += 1;
        if (votes[_call][lastCallVote[_call]] >= redundancy) {
            lastCallVote[_call] += 1;
            _;
        }
    }

    modifier onlyMember() {
        _;
    }

    constructor() {
        //
    }
}
