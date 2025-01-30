// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NeuronGovernance is Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction, GovernorTimelockControl {
    using SafeMath for uint256;

    uint256 public constant MAX_ACTIONS_PER_PROPOSAL = 10;
    uint256 public constant PROPOSAL_THRESHOLD_PERCENT = 1; // 1% of total supply

    mapping(address => uint256) public lastProposalTime;
    uint256 public proposalCooldown = 7 days;

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => ProposalVote) public proposalVotes;
    mapping(address => address) public voteDelegations;

    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);
    event VoteDelegated(address indexed delegator, address indexed delegatee);

    constructor(IVotes _token, TimelockController _timelock)
        Governor("NeuronGovernance")
        GovernorSettings(1 /* 1 block */, 45818 /* 1 week */, _token.totalSupply().mul(PROPOSAL_THRESHOLD_PERCENT).div(100))
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
        GovernorTimelockControl(_timelock)
    {}

    function propose(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description)
        public override(Governor, IGovernor) returns (uint256)
    {
        require(targets.length <= MAX_ACTIONS_PER_PROPOSAL, "Too many actions per proposal");
        require(block.timestamp >= lastProposalTime[msg.sender].add(proposalCooldown), "Proposal cooldown period not met");

        lastProposalTime[msg.sender] = block.timestamp;
        return super.propose(targets, values, calldatas, description);
    }

        function castVote(uint256 proposalId, uint8 support) public override returns (uint256) {
        address voter = msg.sender;
        if (voteDelegations[msg.sender] != address(0)) {
            voter = voteDelegations[msg.sender];
        }

        ProposalVote storage proposalVote = proposalVotes[proposalId];
        require(!proposalVote.hasVoted[voter], "GovernorVotingSimple: vote already cast");
        proposalVote.hasVoted[voter] = true;

        uint256 weight = getVotes(voter, proposalSnapshot(proposalId));

        if (support == 0) {
            proposalVote.againstVotes = proposalVote.againstVotes.add(weight);
        } else if (support == 1) {
            proposalVote.forVotes = proposalVote.forVotes.add(weight);
        } else if (support == 2) {
            proposalVote.abstainVotes = proposalVote.abstainVotes.add(weight);
        } else {
            revert("GovernorVotingSimple: invalid value for enum VoteType");
        }

        emit VoteCast(voter, proposalId, support, weight, "");

        return weight;
    }

    function castVoteWithReason(uint256 proposalId, uint8 support, string calldata reason) public override returns (uint256) {
        uint256 weight = castVote(proposalId, support);
        emit VoteCast(msg.sender, proposalId, support, weight, reason);
        return weight;
    }

    function delegateVote(address delegatee) public {
        require(delegatee != msg.sender, "Cannot delegate to self");
        voteDelegations[msg.sender] = delegatee;
        emit VoteDelegated(msg.sender, delegatee);
    }

    function setProposalThreshold(uint256 newProposalThreshold) public onlyGovernance {
        _setProposalThreshold(newProposalThreshold);
    }

    function setVotingDelay(uint256 newVotingDelay) public onlyGovernance {
        _setVotingDelay(newVotingDelay);
    }

    function setVotingPeriod(uint256 newVotingPeriod) public onlyGovernance {
        _setVotingPeriod(newVotingPeriod);
    }

    function setProposalCooldown(uint256 newCooldown) public onlyGovernance {
        proposalCooldown = newCooldown;
    }

    function quorum(uint256 blockNumber) public view override returns (uint256) {
        return super.quorum(blockNumber);
    }

    function getVotes(address account, uint256 blockNumber) public view override returns (uint256) {
        return super.getVotes(account, blockNumber);
    }

    function state(uint256 proposalId) public view override returns (ProposalState) {
        return super.state(proposalId);
    }

    function proposalThreshold() public view override returns (uint256) {
        return super.proposalThreshold();
    }

    function _execute(uint256 proposalId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal override
    {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal override returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override returns (address) {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}