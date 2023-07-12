// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract TeamRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Team {
        string name;
        string telegram;
        address teamCreator;
        EnumerableSet.AddressSet members;
        EnumerableSet.AddressSet candidates;
        mapping(address => uint256) candidateVotes;
        mapping(address => mapping(address => bool)) hasPlayerVotedForCandidate;
    }

    // Player data
    mapping(address => string) public playerTelegramHandles;
    mapping(address => bool) public playerInTeam;
    mapping(address => uint256) public playerTeamMapping;
    EnumerableSet.AddressSet private players;

    // Team data
    uint256 private teamsCount;
    mapping(uint256 => Team) teams;

    // Which teams user has applied to
    mapping(address => EnumerableSet.UintSet) candidateTeams;

    // Control parameters
    uint256 constant maxPlayersPerTeam = 10;
    uint256 constant maxCandidacies = 10;

    // Events
    event CandidacyRemoved(uint256, address);
    event CandidateVote(uint256, address);
    event NewCandidate(uint256, address);
    event NewTeamMember(uint256, address);
    event NewTeam(uint256);

    /**
     * @notice creates new team and adds caller to the team
     */
    function createNewTeam(string memory _name, string memory _telegram)
        external
    {
        require(!playerInTeam[msg.sender], "Already in a team");
        Team storage newTeam = teams[teamsCount++];
        newTeam.name = _name;
        newTeam.telegram = _telegram;
        newTeam.teamCreator = msg.sender;
        newTeam.members.add(msg.sender);
        playerInTeam[msg.sender] = true;
        playerTeamMapping[msg.sender] = teamsCount - 1;
        players.add(msg.sender);
        emit NewTeam(teamsCount - 1);
    }

    /**
     * @notice votes member onto team and adds to team if vote is final
     */
    function voteForCandidate(address _candidate) external {
        require(!playerInTeam[_candidate], "Candidate already in a team");
        uint256 playerTeamIndex = playerTeamMapping[msg.sender];
        Team storage playerTeam = teams[playerTeamIndex];
        require(
            playerTeam.members.length() < maxPlayersPerTeam,
            "Team is full"
        );
        require(
            !playerTeam.hasPlayerVotedForCandidate[msg.sender][_candidate],
            "Your upvote bucket is empty"
        );
        playerTeam.candidateVotes[_candidate]++;
        playerTeam.hasPlayerVotedForCandidate[msg.sender][_candidate] = true;
        emit CandidateVote(playerTeam.candidateVotes[_candidate], _candidate);
    }

    function unvoteForCandidate(address _candidate) external {
        uint256 playerTeamIndex = playerTeamMapping[msg.sender];
        Team storage playerTeam = teams[playerTeamIndex];
        require(
            playerTeam.hasPlayerVotedForCandidate[msg.sender][_candidate],
            "Your unvote bucket is empty"
        );
        playerTeam.candidateVotes[_candidate] -= 1;
        playerTeam.hasPlayerVotedForCandidate[msg.sender][_candidate] = false;
        emit CandidateVote(playerTeam.candidateVotes[_candidate], _candidate);
    }

    function addCandidacy(uint256 _teamIndex) external {
        require(_teamIndex < teamsCount, "Nice try sweetie pie");
        require(!playerInTeam[msg.sender], "Already in a team");
        require(
            candidateTeams[msg.sender].length() < maxCandidacies,
            "Max candidacies limit"
        );
        Team storage team = teams[_teamIndex];
        require(!team.candidates.contains(msg.sender), "Patience, senpai");
        require(team.members.length() < maxPlayersPerTeam, "Team is full");
        team.candidates.add(msg.sender);
        candidateTeams[msg.sender].add(_teamIndex);
        emit NewCandidate(_teamIndex, msg.sender);
    }

    function removeCandidacy(uint256 _teamIndex) external {
        require(!playerInTeam[msg.sender], "Already in a team");
        Team storage team = teams[_teamIndex];
        team.candidates.remove(msg.sender);
        candidateTeams[msg.sender].remove(_teamIndex);
        emit CandidacyRemoved(_teamIndex, msg.sender);
    }

    function acceptInvitation(uint256 _teamIndex) external {
        require(!playerInTeam[msg.sender], "Already in a team");
        require(_teamIndex < teamsCount, "Nice try sweetie pie");
        Team storage team = teams[_teamIndex];
        require(team.members.length() <= maxPlayersPerTeam, "Team is full");
        require(
            team.candidateVotes[msg.sender] >= team.members.length(),
            "Missing quorum"
        );
        team.members.add(msg.sender);
        players.add(msg.sender);
        emit NewTeamMember(_teamIndex, msg.sender);
    }

    function removePlayerFromTeam(uint256 _teamIndex, address _player)
        external
    {}

    /**
     * @notice returns flag indicating whether or not player has already voted for candidate
     */
    function hasPlayerVotedForCandidate(address _candidate)
        external
        view
        returns (bool)
    {
        return
            teams[playerTeamMapping[msg.sender]].hasPlayerVotedForCandidate[
                msg.sender
            ][_candidate];
    }

    /**
     * @notice updates caller telegram handle
     */
    function updateTelegramHandle(string memory _telegramHandle) external {
        playerTelegramHandles[msg.sender] = _telegramHandle;
    }

    /**
     * @notice gets player telegram handle
     */
    function playerTelegramHandle(address _player)
        external
        view
        returns (string memory)
    {
        return playerTelegramHandles[_player];
    }

    /**
     * @notice returns the number of players
     */
    function numberOfPlayers() external view returns (uint256) {
        return players.length();
    }

    /**
     * @notice returns the player address at the specified index
     */
    function playerAtIndex(uint256 _playerIndex)
        external
        view
        returns (address)
    {
        return players.at(_playerIndex);
    }

    function playerTeam(address _player) external view returns (uint256) {
        if (playerInTeam[_player]) {
            return playerTeamMapping[_player];
        }
        return type(uint256).max;
    }

    /**
     * @notice returns the number of teams
     */
    function numberOfTeams() external view returns (uint256) {
        return teamsCount;
    }

    /**
     * @notice returns team at index
     */
    function teamAtIndex(uint256 _teamIndex)
        external
        view
        returns (
            string memory,
            string memory,
            address,
            bytes32[] memory,
            bytes32[] memory
        )
    {
        return (
            teams[_teamIndex].name,
            teams[_teamIndex].telegram,
            teams[_teamIndex].teamCreator,
            teams[_teamIndex].members._inner._values,
            teams[_teamIndex].candidates._inner._values
        );
    }

    /**
     * @notice returns number of members on team
     */
    function teamMembersCount(uint256 _teamIndex)
        external
        view
        returns (uint256)
    {
        return teams[_teamIndex].members.length();
    }

    /**
     * @notice gets number of members on team at index
     * @param _teamIndex index of team to query
     */
    function numberOfMembersOnTeam(uint256 _teamIndex)
        external
        view
        returns (uint256)
    {
        return teams[_teamIndex].members.length();
    }

    /**
     * @notice gets number of members on specified team
     * @param _teamIndex index of team to query
     * @param _userIndex index of teammember to query
     */
    function teamMemberAtIndex(uint256 _teamIndex, uint256 _userIndex)
        external
        view
        returns (address)
    {
        return teams[_teamIndex].members.at(_userIndex);
    }

    function candidateVoteCount(uint256 _teamIndex, address _candidate)
        external
        view
        returns (uint256)
    {
        return teams[_teamIndex].candidateVotes[_candidate];
    }

    function playerCandidaciesCount(address _player)
        external
        view
        returns (uint256)
    {
        return candidateTeams[_player].length();
    }

    function playerCandidacyAtIndex(uint256 _index)
        external
        view
        returns (uint256)
    {
        return candidateTeams[msg.sender].at(_index);
    }
}
