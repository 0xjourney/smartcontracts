// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Progress {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    struct PlayerProgress {
        uint256 currentMeters;
        uint256 metersPerSecond;
        uint256 lastUpdatedTimestamp;
        uint256 freeBackpacksMinted;
    }

    mapping(address => PlayerProgress) public players;

    uint256 public constant metersDecimals = 18;
    address public immutable nftRegistry;

    event PlayerMetersUpdated(address, uint256, uint256, uint256);
    event ManualPlayerMeterUpdate(address, uint256, uint256);
    event MpsUpdate(address, uint256, uint256, uint256);

    modifier definitelyNotYou() {
        require(
            msg.sender == nftRegistry,
            "shoopity doopity doo, this function be not for you"
        );
        _;
    }

    // TODO add support to check if user is registered player when updating stuff
    constructor(address _nftRegistry) {
        nftRegistry = _nftRegistry;
    }

    function isPlayerEligibleForFreeBackpack(address _player)
        external
        view
        returns (bool)
    {
        uint256 playerMeters = getPlayerMeters(_player);
        return
            playerMeters / (4000 * 10**metersDecimals) >
            players[_player].freeBackpacksMinted;
    }

    function updatePlayerMeters(
        address _player,
        uint256 _mpsChange,
        bool _add
    ) external definitelyNotYou {
        PlayerProgress storage player = players[_player];
        uint256 delta = block.timestamp - player.lastUpdatedTimestamp;
        player.currentMeters +=
            (player.metersPerSecond * delta) /
            10**metersDecimals;
        player.lastUpdatedTimestamp = block.timestamp;
        if (_add) {
            player.metersPerSecond += _mpsChange;
        } else {
            player.metersPerSecond -= _mpsChange;
        }
        emit PlayerMetersUpdated(
            _player,
            player.currentMeters,
            player.metersPerSecond,
            block.timestamp
        );
    }

    function updatePlayerMetersPerSecond(address _player, uint256 _mps)
        external
        definitelyNotYou
    {
        players[_player].currentMeters = getPlayerMeters(_player);
        players[_player].lastUpdatedTimestamp = block.timestamp;
        players[_player].metersPerSecond += _mps;
        emit MpsUpdate(
            _player,
            players[_player].currentMeters,
            players[_player].metersPerSecond,
            block.timestamp
        );
    }

    /**
     * @notice updates player meters, should only be called from H&P registry
     */
    function updatePlayerMeters(address _player, uint256 _meters)
        external
        definitelyNotYou
    {
        //
    }

    /**
     * @notice returns number of meters for player, takes into account meter stoppages
     */
    function getPlayerMeters(address _player) public view returns (uint256) {
        PlayerProgress storage player = players[_player];
        if (block.timestamp <= player.lastUpdatedTimestamp) {
            return player.currentMeters;
        }
        uint256 delta = block.timestamp - player.lastUpdatedTimestamp;
        uint256 elapsedMeters = (player.metersPerSecond * delta) /
            10**metersDecimals;
        return player.currentMeters + elapsedMeters;
    }

    /**
     * @notice gets the current mps for player
     */
    function getPlayerMPS(address _player) external view returns (uint256) {
        //
        return 0;
    }

    function updatePlayerMeters(address _player) private {
        PlayerProgress storage player = players[_player];
        uint256 delta = block.timestamp - player.lastUpdatedTimestamp;
        player.currentMeters +=
            (player.metersPerSecond * delta) /
            10**metersDecimals;
        player.lastUpdatedTimestamp = block.timestamp;
        emit ManualPlayerMeterUpdate(
            _player,
            player.currentMeters,
            block.timestamp
        );
    }

    // this can cause problems with boosters/handicaps
    function manualMetersUpdate() external {
        PlayerProgress storage player = players[msg.sender];
        uint256 delta = block.timestamp - player.lastUpdatedTimestamp;
        player.currentMeters +=
            (player.metersPerSecond * delta) /
            10**metersDecimals;
        player.lastUpdatedTimestamp = block.timestamp;
        emit ManualPlayerMeterUpdate(
            msg.sender,
            player.currentMeters,
            block.timestamp
        );
    }

    // HANDICAPS ARE NOT SELF RESOLVING
    //
    // NO OTHER CASES, HANDICAP CANNOT BE
    // APPLIED IF PLAYER IS ALREADY HANDICAPPED
    //
    // How to apply handicap?
    // 1: Resolve any expired Handicaps
    //      1a: Calculate meters player has obtained since the handicap ended
    // 2: Apply meter penalty immediately in Progress.sol
    // 3: Save meters player is at and expiration date of stoppage
    //

    // POWERUPS ARE SELF-RESOLVING
    //
    // NO OTHER CASES, POWERUPS DO NOTHING IF
    // PLAYER HAS NO ACTIVE HANDICAP (UNLESS IT'S IMMEDIATE METER BONUS)
    //
    // How to apply PowerUp?
    // 1: Resolve old handicaps if not yet resolved
    // 2: Check if PowerUp applies to active Handicap
    //      2a: if yes, give users his meters back, and start player meters again
    //      2b: if no, PowerUp does nothing
    // 3: Update player meters
}
