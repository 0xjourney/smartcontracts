// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../external/libraries/TransferHelper.sol";

import "../interfaces/IERC20Extended.sol";
import "../interfaces/IProgress.sol";

abstract contract Staking {
    mapping(address => uint256) private stakedBalance;

    uint256 public immutable maximumStakingAmount;
    uint256 public immutable minimumStakingAmount;
    uint256 public immutable mps;
    uint256 public immutable NFTType;

    IERC20Extended public immutable journey;
    IProgress private progress;

    constructor(
        address _journey,
        address _progress,
        uint256 _maxStakeAmount,
        uint256 _mps,
        uint256 _type
    ) {
        mps = _mps;
        NFTType = _type;
        progress = IProgress(_progress);
        journey = IERC20Extended(_journey);
        maximumStakingAmount = _maxStakeAmount * 10**journey.decimals();
        minimumStakingAmount =
            (5 * _maxStakeAmount * 10**journey.decimals()) /
            100;
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "What are you doing");
        require(
            stakedBalance[msg.sender] + _amount <= maximumStakingAmount,
            "I'm full"
        );
        stakedBalance[msg.sender] += _amount;
        TransferHelper.safeTransferFrom(
            address(journey),
            msg.sender,
            address(this),
            _amount
        );
        progress.updatePlayerMetersPerSecond(
            msg.sender,
            metersPerSecond(msg.sender)
        );
    }

    function unstake(uint256 _amount) external {
        require(_amount > 0, "why are you running");
        require(_amount <= stakedBalance[msg.sender], "you're empty");
        stakedBalance[msg.sender] -= _amount;
        TransferHelper.safeTransfer(address(journey), msg.sender, _amount);
        progress.updatePlayerMetersPerSecond(
            msg.sender,
            metersPerSecond(msg.sender)
        );
    }

    function userStakedBalance(address _staker) public view returns (uint256) {
        return stakedBalance[_staker];
    }

    function metersPerSecond(address _staker) public view returns (uint256) {
        // TODO verify this is ok (prolly not ok)?
        return (stakedBalance[_staker] / maximumStakingAmount) * mps;
    }
}
