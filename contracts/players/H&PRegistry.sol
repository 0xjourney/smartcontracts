// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../interfaces/IProgress.sol";

contract HnPRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Powerup {
        address deployer;
        address target;
        uint256 deployedTimestamp;
        uint256 effectEndTimestamp;
        uint256 nftID;
        uint256 nftType;
        uint256 counteredID;
        bool success;
    }

    struct Handicap {
        address deployer;
        address target;
        uint256 meterPenalty;
        uint256 metersAtStoppage;
        uint256 deployedTimestamp;
        uint256 effectEndTimestamp;
        uint256 nftID;
        uint256 nftType;
        bool success;
        bool countered;
    }

    // registry contains registered NFTs from each player
    address public nftRegistry;
    // collection of all nft addresses, since
    // minting happens in the nft smartcontract
    EnumerableSet.AddressSet private nfts;

    address private immutable owner;
    IProgress private progressRegistry;

    // stores all handicaps/powerups as they occured
    Powerup[] private allPowerups;
    Handicap[] private allHandicaps;

    // active powerups & handicaps on the player
    mapping(address => uint256) private snowballShieldCooldowns;
    mapping(address => uint256) private activePlayerHandicap;
    // powerups & handicaps used on the user
    mapping(address => EnumerableSet.UintSet) private playerPowerups;
    mapping(address => EnumerableSet.UintSet) private playerHandicaps;
    // powerups & handicaps that the player used
    mapping(address => EnumerableSet.UintSet) private usedPowerups;
    mapping(address => EnumerableSet.UintSet) private usedHandicaps;

    event PowerupUsed(address, address, uint256, bool, uint256);
    event HandicapUsed(address, address, uint256, bool, uint256);

    modifier onlyNFT() {
        require(
            nfts.contains(msg.sender),
            "bee boop boop, skibbidy dibbidy doop"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function updateNFTAddresses(address[] memory _nfts, bool _add) external {
        require(msg.sender == owner, "labba dabba doo");
        for (uint256 i = 0; i < _nfts.length; i++) {
            if (_add) {
                nfts.add(_nfts[i]);
            } else {
                nfts.remove(_nfts[i]);
            }
        }
    }

    /**
     * @notice resolves an active handicap
     * @param _player   address of the player whose handicap we want to resolve
     * @return bool     returns true if the player can be handicapped, else false
     */
    function resolveExpiredHandicap(address _player) private returns (bool) {
        if (
            activePlayerHandicap[_player] != type(uint256).max &&
            block.timestamp >=
            allHandicaps[activePlayerHandicap[_player]].effectEndTimestamp
        ) {
            uint256 playerMPS = progressRegistry.getPlayerMPS(_player);
            uint256 delta = block.timestamp -
                allHandicaps[activePlayerHandicap[_player]].effectEndTimestamp;
            uint256 metersSinceHandicapExpired = delta * playerMPS;
            progressRegistry.updatePlayerMeters(
                _player,
                allHandicaps[activePlayerHandicap[_player]].metersAtStoppage +
                    metersSinceHandicapExpired
            );
            activePlayerHandicap[_player] = type(uint256).max;
            return true;
        } else if (activePlayerHandicap[_player] == type(uint256).max) {
            return true;
        }
        return false;
    }

    /**
     * @notice attempts to resolve a handicap with its matching counter
     */
    function resolveCounteredHandicap(address _player, Powerup memory _powerup)
        private
        returns (uint256)
    {
        // this will resolve a player handicap if applicable
        if (
            _powerup.nftType !=
            allHandicaps[activePlayerHandicap[_player]].nftType
        ) {
            // used wrong counter
            return type(uint256).max;
        }
        if (
            _powerup.nftType == 0 &&
            allHandicaps[activePlayerHandicap[_player]].nftType == 0
        ) {
            // remove snowball
            snowballShieldCooldowns[_player] = block.timestamp + 36 hours;
        }
        progressRegistry.updatePlayerMeters(
            _player,
            allHandicaps[activePlayerHandicap[_player]].metersAtStoppage +
                allHandicaps[activePlayerHandicap[_player]].meterPenalty
        );
        allHandicaps[activePlayerHandicap[_player]].countered = true;
        allHandicaps[activePlayerHandicap[_player]].effectEndTimestamp = block
            .timestamp;
        uint256 result = activePlayerHandicap[_player];
        activePlayerHandicap[_player] = type(uint256).max;
        return result;
    }

    /**
     * @notice handicaps a player
     * @param _target   address of the player to be handicapped
     */
    function rekPlayer(
        address _target,
        address _deployer,
        uint256 _meterPenalty,
        uint256 _duration,
        uint256 _nftID,
        uint256 _nftType
    ) external onlyNFT {
        uint256 playerCurrentMeters = progressRegistry.getPlayerMeters(_target);
        if (playerCurrentMeters > _meterPenalty) {
            playerCurrentMeters -= _meterPenalty;
        } else {
            playerCurrentMeters = 0;
        }
        Handicap memory handicap = Handicap({
            deployer: _deployer,
            target: _target,
            meterPenalty: _meterPenalty,
            metersAtStoppage: playerCurrentMeters,
            deployedTimestamp: block.timestamp,
            effectEndTimestamp: block.timestamp + _duration,
            nftID: _nftID,
            nftType: _nftType,
            success: true,
            countered: false
        });
        if (!resolveExpiredHandicap(_target)) {
            // unsuccessful deployement
            handicap.success = false;
        } else {
            // successful deployement
            if (
                handicap.nftType == 0 &&
                allHandicaps[activePlayerHandicap[_target]].nftType == 0
            ) {
                snowballShieldCooldowns[_target] = block.timestamp + 7 hours;
            }
            activePlayerHandicap[_target] = allHandicaps.length;

            // Why do this V ??
            progressRegistry.updatePlayerMeters(_target, playerCurrentMeters);
            // Why do this ^ ??
        }
        playerHandicaps[_target].add(allHandicaps.length);
        usedHandicaps[_deployer].add(allHandicaps.length);
        allHandicaps.push(handicap);
        emit HandicapUsed(
            _deployer,
            _target,
            block.timestamp,
            handicap.success,
            allHandicaps.length - 1
        );
    }

    /**
     * @notice uses a booster/powerup in the attempt to remove a handicap
     */
    function boostPlayer(
        address _target,
        address _deployer,
        uint256 _effectDuration,
        uint256 _type,
        uint256 _nftID
    ) external onlyNFT {
        Powerup memory powerup = Powerup({
            deployer: _deployer,
            target: _target,
            deployedTimestamp: block.timestamp,
            effectEndTimestamp: block.timestamp + _effectDuration,
            nftID: _nftID,
            nftType: _type,
            counteredID: type(uint256).max,
            success: true
        });
        if (!resolveExpiredHandicap(_target)) {
            // active handicap
            powerup.counteredID = resolveCounteredHandicap(_target, powerup);
        } else {
            // no active handicap
            if (powerup.nftType == 0) {
                // give this man some milk
                snowballShieldCooldowns[_target] = block.timestamp + 36 hours;
            }
            powerup.success = false;
        }
        playerPowerups[_target].add(allPowerups.length);
        usedPowerups[_deployer].add(allPowerups.length);
        allPowerups.push(powerup);
        emit PowerupUsed(
            _deployer,
            _target,
            block.timestamp,
            powerup.success,
            allPowerups.length - 1
        );
    }

    /**
     * @notice gets shield duration if active
     */
    function snowballShieldCooldown(address _player)
        external
        view
        returns (uint256)
    {
        if (block.timestamp < snowballShieldCooldowns[_player]) {
            return snowballShieldCooldowns[_player] - block.timestamp;
        }
        return 0;
    }

    /**
     * @notice returns number of handicaps used by player
     */
    function numberOfPlayerUsedHandicaps(address _player)
        external
        view
        returns (uint256)
    {
        return usedHandicaps[_player].length();
    }

    /**
     * @notice returns handicap used by player
     */
    function usedPlayerHandicapAtIndex(address _player, uint256 _index)
        external
        view
        returns (Handicap memory)
    {
        return allHandicaps[usedHandicaps[_player].at(_index)];
    }

    function numberOfHandicapsUsedOnPlayer(address _player)
        external
        view
        returns (uint256)
    {
        return playerHandicaps[_player].length();
    }

    function playerHandicapAtIndex(address _player, uint256 _index)
        external
        view
        returns (Handicap memory)
    {
        return allHandicaps[playerHandicaps[_player].at(_index)];
    }
}
