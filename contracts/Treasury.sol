// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./external/libraries/TransferHelper.sol";

import "./interfaces/IMigrate.sol";
import "./MultiSig.sol";

/**
 * @dev
 */
contract Treasury is MultiSig, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    struct RewardPool {
        uint256 remaining;
        uint256 amount;
        uint256 poolStart;
        uint256 poolEnd;
        // each time a sherpa is minted/transferred that event
        // must be registered here so that we know what the reward is for each player
        // rewards can only be paid out the day after the pool ends
        uint256 rewardDivisor;
        uint256 withdrawls;
        address token;
        bool weth;
    }

    struct SherpaOwner {
        uint256 ownershipStart;
    }

    // for registering the earliest date a player owned a Sherpa for.
    // If the owner has at least 2 Sherpas, this will store the earliest
    // ownership date so that the player doesn't lose access to potential
    // reward pools he hasn't claimed
    mapping(address => uint256) private playerSherpaStakingStart;

    // daily/weekly sherpa rewards pools
    RewardPool[] private dailySherpaRewards;
    mapping(address => mapping(uint256 => bool)) private dailyRewardWithdrawn;
    RewardPool[] private weeklySherpaRewards;
    // in order to not register special addresses for sherpa rewards
    EnumerableSet.AddressSet private ignorableOwners;

    // season start/end timestamp
    uint256 public immutable seasonStart;
    uint256 public immutable seasonEnd;
    uint256 public constant journeyLength = 884800 * 10**9;
    uint256 public winnerJackpot;

    // control flags
    bool public newDailyRewardsOn;
    bool public dailyRewardsOn;
    bool public newWeeklyRewardsOn;
    bool public weeklyRewardsOn;

    // for migrating rewards to new treasury for new season
    IMigrate public migration;

    modifier onlyJourneyOrSherpa() {
        _;
    }

    modifier onlyNFTRegistry() {
        _;
    }

    // METERS 18 decimal places
    // CALCULATE % of tokens using max staking amount, multiply this by MPS
    // TODO implement 400 METER free basic/shiny backpack
    // TODO implement way to allow N backpacks to be bought thru treasury
    // TODO implement mandatory burning of 5 Backpacks & 1500$ of $Journey to mint Sherpa
    // TODO implement daily 1% volume reward for Sherpa holders
    // TODO implement weekly 1% volume $Journey reward for team with highest meters, handicap goes to teammember with most meters
    // TODO implement 1% seasonal $Journey reward to winning team (who reaches everest)
    // TODO implement win mechanism for 1st team to reach 884800 meters
    // TODO implement season end after 40 days (and season start)
    // TODO implement 80% reward for winning team if no one reaches the summit and 10% for season 2, 10% for devs
    // TODO implement special smartcontract for registering rewards, this way token taxes can be modified in any way we might need
    // TODO implement method to migrate treasury to new v2 treasury
    constructor(uint256 _start, uint256 _end) {
        seasonStart = _start;
        seasonEnd = _end;
        ignorableOwners.add(address(this));
    }

    fallback() external payable {}

    /**
     * @notice
     */
    function registerDailyReward(
        address _token,
        uint256 _amount,
        bool _weth
    ) external onlyJourneyOrSherpa {
        if (seasonStart <= block.timestamp && block.timestamp <= seasonEnd) {
            // TODO create new reward pool
            // TODO if there are no sherpa owners, pool the reward until one arises
            // TODO register rewards using Journey token trades as events
        }
    }

    /**
     * @notice
     */
    function registerWeeklyReward(
        address _token,
        uint256 _amount,
        bool _weth
    ) external onlyJourneyOrSherpa {
        //
    }

    /**
     * @notice
     */
    function migrateTreasury(
        address _token,
        uint256 _amount,
        bool _weth
    ) external requireQuorum {
        require(address(migration) != address(0), "migration address not set");
        if (_weth) {
            TransferHelper.safeTransferETH(address(migration), _amount);
        } else {
            TransferHelper.safeTransfer(_token, address(migration), _amount);
        }
        migration.migrateToken(_token, _amount, _weth);
    }

    /**
     * @notice
     */
    function updateMigrationAddress(address _migrator) external requireQuorum {
        migration = IMigrate(_migrator);
    }

    function updateRewardsFlags(
        bool _dailyOn,
        bool _weeklyOn,
        bool _newDailyOn,
        bool _newWeeklyOn
    ) external requireQuorum {
        dailyRewardsOn = _dailyOn;
        weeklyRewardsOn = _weeklyOn;
        newDailyRewardsOn = _newDailyOn;
        newWeeklyRewardsOn = _newWeeklyOn;
    }

    function updateSherpaOwnershipStart(
        address _player,
        uint256 _previouslyOwnedSherpas,
        uint256 _currentlyOwnedSherpas
    ) external onlyNFTRegistry {
        // TODO use sherpa staking event to register # of people eligible for daily pool rewards
        if (ignorableOwners.contains(_player)) {
            return;
        }
        if (_currentlyOwnedSherpas == 0) {
            dailySherpaRewards[dailySherpaRewards.length - 1]
                .rewardDivisor -= 1;
            playerSherpaStakingStart[_player] = type(uint256).max;
        } else if (_previouslyOwnedSherpas == 0) {
            if (dailySherpaRewards.length > 0) {
                dailySherpaRewards[dailySherpaRewards.length - 1]
                    .rewardDivisor += 1;
            }
            playerSherpaStakingStart[_player] = block.timestamp;
        }
    }

    /**
     * @notice claims the reward from a given reward pool
     */
    function claimDailyReward(uint256 _poolID) public nonReentrant {
        RewardPool storage pool = dailySherpaRewards[_poolID];
        require(canClaimDailyReward(msg.sender, _poolID), "sorry but no");
        uint256 amount = pool.amount / pool.rewardDivisor;
        if (pool.withdrawls + 1 == pool.rewardDivisor) {
            amount = pool.amount;
        }
        if (pool.weth) {
            TransferHelper.safeTransferETH(msg.sender, amount);
        } else {
            TransferHelper.safeTransfer(pool.token, msg.sender, amount);
        }
        pool.remaining -= amount;
        pool.withdrawls += 1;
        dailyRewardWithdrawn[msg.sender][_poolID] = true;
    }

    /**
     * @notice returns a value indicating whether or not a player has access to a given reward pool
     */
    function canClaimDailyReward(address _player, uint256 _poolID)
        public
        view
        returns (bool)
    {
        return
            playerSherpaStakingStart[_player] <=
            dailySherpaRewards[_poolID].poolEnd &&
            block.timestamp > dailySherpaRewards[_poolID].poolEnd &&
            !dailyRewardWithdrawn[msg.sender][_poolID] &&
            dailyRewardsOn;
    }
}
