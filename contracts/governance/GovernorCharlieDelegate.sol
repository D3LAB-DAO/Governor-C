// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./GovernorCharlieInterfaces.sol";
import "../math/FractionalExponents.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

/**
 * @title GovernorCharlieDelegate
 * 
 * References
 *
 * - https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/GovernorBravoDelegate.sol
 */
contract GovernorCharlieDelegate is
    GovernorCharlieDelegateStorage,
    GovernorCharlieEvents,
    VRFConsumerBase(
        0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token
    ),
    FractionalExponents
{
    /// @notice The number of blocks to represent 1 day in Polygon
    uint public constant ONE_DAY_BLOCKS = 86400 / 2; // blocks

    /// @notice The name of this contract
    string public constant name = "Compound Governor Charlie";

    /// @notice The minimum setable proposal threshold
    uint public constant MIN_PROPOSAL_THRESHOLD = 1000e18; // 1,000 Comp

    /// @notice The maximum setable proposal threshold
    uint public constant MAX_PROPOSAL_THRESHOLD = 100000e18; //100,000 Comp

    /// @notice The minimum setable voting period
    uint public constant MIN_VOTING_PERIOD = ONE_DAY_BLOCKS; // About 24 hours

    /// @notice The max setable voting period
    uint public constant MAX_VOTING_PERIOD = ONE_DAY_BLOCKS * 14; // About 2 weeks

    /// @notice The min setable voting delay
    uint public constant MIN_VOTING_DELAY = 1;

    /// @notice The max setable voting delay
    uint public constant MAX_VOTING_DELAY = ONE_DAY_BLOCKS * 7; // About 1 week

    /// @notice The min setable aggregating period
    uint public constant MIN_AGGREGATING_PERIOD = ONE_DAY_BLOCKS; // About 24 hours

    /// @notice The max setable aggregating period
    uint public constant MAX_AGGREGATING_PERIOD = ONE_DAY_BLOCKS * 14; // About 2 weeks

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    uint public constant quorumVotes = 400000e18; // 400,000 = 4% of Comp

    /// @notice The maximum number of actions that can be included in a proposal
    uint public constant proposalMaxOperations = 10; // 10 actions

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");

    /// @notice The EIP-712 typehash for the finalizing struct used by the contract
    bytes32 public constant FINALIZE_TYPEHASH = keccak256("Finalize(uint256 proposalId)");

    // Constructor inherits VRFConsumerBase
    // 
    // Network: Polygon (Matic)
    // Chainlink VRF Coordinator address: 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255
    // LINK token address:                0x326C977E6efc84E512bB9C30f76E30c160eD06FB
    // Key Hash: 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
    bytes32 public constant keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
    uint public fee = 0.0001 * 10 ** 18; // 0.0001 LINK (Varies by network)

    function feeUpdate(uint newFee) public {
        require(msg.sender == admin, "GovernorCharlie::feeUpdate: admin only");
        fee = newFee;
    }

    // e = 1.05
    // TODO: Dynamic adjustment of `e`
    uint32 public expN = 105;
    uint32 public expD = 100;

    function eUpdate(uint32 newExpN, uint32 newExpD) public {
        require(msg.sender == admin, "GovernorCharlie::eUpdate: admin only");
        expN = newExpN;
        expD = newExpD;
    }

    /** 
     * @notice Chainlink: Requests randomness 
     */
    function requestFlagedRandomness() public returns (bytes32 requestId) {
        require(
            flagedRandoms[requestId].returnTimestamp == 0,
            "Cannot request random number again"
        );
        
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        /* return */ requestId = requestRandomness(keyHash, fee);
        
        flagedRandoms[requestId] = FlagedRandom({
            randomValue: 0,
            returnTimestamp: 0
        });
    }

    /**
     * @notice Chainlink: Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        flagedRandoms[requestId].randomValue = randomness;
        flagedRandoms[requestId].returnTimestamp = block.timestamp;
        // flagedRandoms[requestId].request = true;
    }

    /**
      * @notice Used to initialize the contract during delegator constructor
      * @param timelock_ The address of the Timelock
      * @param comp_ The address of the COMP token
      * @param votingPeriod_ The initial voting period
      * @param votingDelay_ The initial voting delay
      * @param proposalThreshold_ The initial proposal threshold
      */
    function initialize(address timelock_, address comp_, uint votingPeriod_, uint votingDelay_, uint proposalThreshold_, uint aggregatingPeriod_) virtual public {
        require(address(timelock) == address(0), "GovernorCharlie::initialize: can only initialize once");
        require(msg.sender == admin, "GovernorCharlie::initialize: admin only");
        require(timelock_ != address(0), "GovernorCharlie::initialize: invalid timelock address");
        require(comp_ != address(0), "GovernorCharlie::initialize: invalid comp address");
        require(votingPeriod_ >= MIN_VOTING_PERIOD && votingPeriod_ <= MAX_VOTING_PERIOD, "GovernorCharlie::initialize: invalid voting period");
        require(votingDelay_ >= MIN_VOTING_DELAY && votingDelay_ <= MAX_VOTING_DELAY, "GovernorCharlie::initialize: invalid voting delay");
        require(proposalThreshold_ >= MIN_PROPOSAL_THRESHOLD && proposalThreshold_ <= MAX_PROPOSAL_THRESHOLD, "GovernorCharlie::initialize: invalid proposal threshold");
        require(aggregatingPeriod_ >= MIN_AGGREGATING_PERIOD && aggregatingPeriod_ <= MAX_AGGREGATING_PERIOD, "GovernorCharlie::initialize: invalid aggregating period");

        timelock = TimelockInterface(timelock_);
        comp = CompInterface(comp_);
        votingPeriod = votingPeriod_;
        votingDelay = votingDelay_;
        proposalThreshold = proposalThreshold_;
        aggregatingPeriod = aggregatingPeriod_;

        timelock.acceptAdmin();

        initFractionalExponents();
    }

    /**
      * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
      * @param targets Target addresses for proposal calls
      * @param values Eth values for proposal calls
      * @param signatures Function signatures for proposal calls
      * @param calldatas Calldatas for proposal calls
      * @param description String description of the proposal
      * @return Proposal id of new proposal
      */
    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint) {
        // Allow addresses above proposal threshold and whitelisted addresses to propose
        require(comp.getPriorVotes(msg.sender, block.number - 1) > proposalThreshold || isWhitelisted(msg.sender), "GovernorCharlie::propose: proposer votes below proposal threshold");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "GovernorCharlie::propose: proposal function information arity mismatch");
        require(targets.length != 0, "GovernorCharlie::propose: must provide actions");
        require(targets.length <= proposalMaxOperations, "GovernorCharlie::propose: too many actions");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "GovernorCharlie::propose: one live proposal per proposer, found an already active proposal");
          require(proposersLatestProposalState != ProposalState.Pending, "GovernorCharlie::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint startBlock = block.number + votingDelay;
        uint endBlock = startBlock + votingPeriod;

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        PqvMeta storage newPqvMeta = pqvMetas[proposalCount];

        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;

        newProposal.eta = 0;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;

        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;

        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.abstainVotes = 0;

        newProposal.canceled = false;
        newProposal.executed = false;

        newPqvMeta.baseFlagedRandom = 0;
        newPqvMeta.finalizedTime = 0;
        newPqvMeta.aggregatedForVotes = 0;
        newPqvMeta.aggregatedAgainstVotes = 0;
        newPqvMeta.aggregatedAbstainVotes = 0;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
        return newProposal.id;
    }

    /**
      * @notice Queues a proposal of state succeeded
      * @param proposalId The id of the proposal to queue
      */
    function queue(uint proposalId) external {
        require(state(proposalId) == ProposalState.Succeeded, "GovernorCharlie::queue: proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[proposalId];
        uint eta = block.timestamp + timelock.delay();
        for (uint i = 0; i < proposal.targets.length; i++) {
            queueOrRevertInternal(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function queueOrRevertInternal(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "GovernorCharlie::queueOrRevertInternal: identical proposal action already queued at eta");
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    /**
      * @notice Executes a queued proposal if eta has passed
      * @param proposalId The id of the proposal to execute
      */
    function execute(uint proposalId) external payable {
        require(state(proposalId) == ProposalState.Queued, "GovernorCharlie::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{value: proposal.values[i]}(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(proposalId);
    }

    /**
      * @notice Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold
      * @param proposalId The id of the proposal to cancel
      */
    function cancel(uint proposalId) external {
        require(state(proposalId) != ProposalState.Executed, "GovernorCharlie::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];

        // Proposer can cancel
        if(msg.sender != proposal.proposer) {
            // Whitelisted proposers can't be canceled for falling below proposal threshold
            if(isWhitelisted(proposal.proposer)) {
                require((comp.getPriorVotes(proposal.proposer, block.number - 1) < proposalThreshold) && msg.sender == whitelistGuardian, "GovernorCharlie::cancel: whitelisted proposer");
            }
            else {
                require((comp.getPriorVotes(proposal.proposer, block.number - 1) < proposalThreshold), "GovernorCharlie::cancel: proposer above threshold");
            }
        }

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId);
    }

    /**
      * @notice Gets actions of a proposal
      * @param proposalId the id of the proposal
      * @return targets of the proposal actions
      * @return values of the proposal actions
      * @return signatures of the proposal actions
      * @return calldatas of the proposal actions
      */
    function getActions(uint proposalId) external view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /**
      * @notice Gets the receipt for a voter on a given proposal
      * @param proposalId the id of proposal
      * @param voter The address of the voter
      * @return The voting receipt
      */
    function getReceipt(uint proposalId, address voter) external view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    /**
     * @notice Gets the expectation value (EQV)
     */
    function pqvExpect(uint proposalId) public view returns (
        bool isSucceeded, uint aggregatedForVotes, uint aggregatedAgainstVotes, uint aggregatedAbstainVotes
    ) {        
        Proposal storage proposal = proposals[proposalId];

        uint N = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;

        for (uint i = 0; i < participants[proposalId].length; i++) {
            address participant = participants[proposalId][i];
            Receipt memory receipt = proposal.receipts[participant];

            // accumulating
            uint256 res;
            uint8 prec;
            (res, prec) = power(receipt.votes, 1, expN, expD);
            res /= 2 ** prec; // result

            if (receipt.support == 0) {
                if (res >= N) { aggregatedAgainstVotes += sqrt(receipt.votes); }
                else { aggregatedAgainstVotes += sqrt(receipt.votes) * res / N; }
            } else if (receipt.support == 1) {
                if (res >= N) { aggregatedForVotes += sqrt(receipt.votes); }
                else { aggregatedForVotes += sqrt(receipt.votes) * res / N; }
            } else if (receipt.support == 2) {
                if (res >= N) { aggregatedAbstainVotes += sqrt(receipt.votes); }
                else { aggregatedAbstainVotes += sqrt(receipt.votes) * res / N; }
            }
        }

        // proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes
        isSucceeded = (aggregatedForVotes <= aggregatedAgainstVotes) || (aggregatedForVotes < quorumVotes);
    }

    /**
      * @notice Gets the state of a proposal
      * @param proposalId The id of the proposal
      * @return Proposal state
      */
    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId, "GovernorCharlie::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        PqvMeta storage pqvMeta = pqvMetas[proposalId];

        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (/* Finalized condition */ !isFinalizeInternal(proposalId)) {
            return ProposalState.Pending;
        } else if (/* PQV */ pqvResultInternal(proposalId)) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.eta + timelock.GRACE_PERIOD()) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    /**
      * @notice Finalize a vote for a proposal
      * @param proposalId The id of the proposal to finalize on
      */
    function finalizeVote(uint proposalId) external {
        emit FinalizeCast(msg.sender, proposalId, finalizeVoteInternal(msg.sender, proposalId));
    }

    /**
      * @notice Finalize a vote for a proposal by signature
      * @dev External function that accepts EIP-712 signatures for finalizing on proposals.
      */
    function finalizeVoteBySig(uint proposalId, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), block.chainid, address(this)));
        bytes32 structHash = keccak256(abi.encode(FINALIZE_TYPEHASH, proposalId));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "GovernorCharlie::finalizeVoteBySig: invalid signature");
        
        emit FinalizeCast(signatory, proposalId, finalizeVoteInternal(signatory, proposalId));
    }

    /**
      * @notice Internal function that caries out finalizing logic
      * @param voter The voter that is finalizing their vote
      * @param proposalId The id of the proposal to finalize on
      * @return The number of votes finalized
      */
    function finalizeVoteInternal(address voter, uint proposalId) internal returns (uint96) {
        Proposal storage proposal = proposals[proposalId];
        PqvMeta storage pqvMeta = pqvMetas[proposalId];
        Receipt storage receipt = proposal.receipts[voter];

        if (!isFinalizeInternal(proposalId)) {
            finalize(proposalId);
        }

        require(
            (block.number > proposal.endBlock) && (block.number <= proposal.endBlock + aggregatingPeriod) &&
            (state(proposalId) == ProposalState.Pending),
            "GovernorCharlie::finalizeVoteInternal: finalizing stage is closed"
        );

        require(
            receipt.hasVoted == true,
            "GovernorCharlie::finalizeVoteInternal: voter should be voted"
        );

        bytes32 myFlagedRandom = myFlagedRandoms[proposalId][voter];
        FlagedRandom memory indivRandom = flagedRandoms[myFlagedRandom]; // Individual random number
        require(
            (indivRandom.returnTimestamp != 0) &&
            (indivRandom.returnTimestamp <= pqvMeta.finalizedTime),
            "GovernorCharlie::finalizeVoteInternal: not a valid random"
        );

        uint N = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;

        // random
        FlagedRandom memory baseRandom = flagedRandoms[pqvMeta.baseFlagedRandom]; // Base random number
        uint finalRandomValue = baseRandom.randomValue ^ indivRandom.randomValue;
        uint256 res;
        uint8 prec;
        (res, prec) = power(receipt.votes, 1, expN, expD);
        res /= 2 ** prec; // result

        if (res <= (finalRandomValue % N)) {
            return 0;
        }

        // accumulating
        if (receipt.support == 0) {
            pqvMeta.aggregatedAgainstVotes += sqrt(receipt.votes);
        } else if (receipt.support == 1) {
            pqvMeta.aggregatedForVotes += sqrt(receipt.votes);
        } else if (receipt.support == 2) {
            pqvMeta.aggregatedAbstainVotes += sqrt(receipt.votes);
        }

        return receipt.votes;
    }

    function pqvResultInternal(uint proposalId) internal view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        PqvMeta storage pqvMeta = pqvMetas[proposalId];

        // proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes
        return (
            (pqvMeta.aggregatedForVotes <= pqvMeta.aggregatedAgainstVotes) ||
            (pqvMeta.aggregatedForVotes < (quorumVotes * pqvMeta.aggregatedForVotes / proposal.forVotes)) // scaling
        );
    }

    /**
     * @notice Return false if unfinalized
     */
    function isFinalizeInternal(uint proposalId) internal view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        PqvMeta storage pqvMeta = pqvMetas[proposalId];

        if (block.number > proposal.endBlock + aggregatingPeriod) {
            // TODO: error exception
            return true;
        }
        else if (flagedRandoms[pqvMeta.baseFlagedRandom].returnTimestamp == 0) {
            return false;
        }
        else {
            return true;
        }
    }

    /**
     * @notice Finalize the proposal
     */
    function finalize(uint proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        PqvMeta storage pqvMeta = pqvMetas[proposalId];
        require(
            block.number > proposal.endBlock,
            "GovernorCharlie::requestBaseFlagedRandom: voting is already finalized"
        );

        if (block.number > proposal.endBlock + aggregatingPeriod) {
            // TODO: error exception
        }
        else if (flagedRandoms[pqvMeta.baseFlagedRandom].returnTimestamp == 0) {
            pqvMeta.baseFlagedRandom = requestFlagedRandomness(); // request base random
        }
        else {
            if (pqvMeta.finalizedTime != 0) {
                pqvMeta.finalizedTime = block.timestamp; // finalize
                emit ProposalFinalized(proposalId);
            }
        }
    }

    /**
      * @notice Cast a vote for a proposal
      * @param proposalId The id of the proposal to vote on
      * @param support The support value for the vote. 0=against, 1=for, 2=abstain
      */
    function castVote(uint proposalId, uint8 support) external {
        emit VoteCast(msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support), "");
    }

    /**
      * @notice Cast a vote for a proposal with a reason
      * @param proposalId The id of the proposal to vote on
      * @param support The support value for the vote. 0=against, 1=for, 2=abstain
      * @param reason The reason given for the vote by the voter
      */
    function castVoteWithReason(uint proposalId, uint8 support, string calldata reason) external {
        emit VoteCast(msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support), reason);
    }

    /**
      * @notice Cast a vote for a proposal by signature
      * @dev External function that accepts EIP-712 signatures for voting on proposals.
      */
    function castVoteBySig(uint proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), block.chainid, address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "GovernorCharlie::castVoteBySig: invalid signature");
        emit VoteCast(signatory, proposalId, support, castVoteInternal(signatory, proposalId, support), "");
    }

    /**
      * @notice Internal function that caries out voting logic
      * @param voter The voter that is casting their vote
      * @param proposalId The id of the proposal to vote on
      * @param support The support value for the vote. 0=against, 1=for, 2=abstain
      * @return The number of votes cast
      */
    function castVoteInternal(address voter, uint proposalId, uint8 support) internal returns (uint96) {
        require(state(proposalId) == ProposalState.Active, "GovernorCharlie::castVoteInternal: voting is closed");
        require(support <= 2, "GovernorCharlie::castVoteInternal: invalid vote type");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "GovernorCharlie::castVoteInternal: voter already voted");
        uint96 votes = comp.getPriorVotes(voter, proposal.startBlock);

        if (support == 0) {
            proposal.againstVotes += votes;
        } else if (support == 1) {
            proposal.forVotes += votes;
        } else if (support == 2) {
            proposal.abstainVotes += votes;
        }

        participants[proposalId].push(voter);
        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;
        
        myFlagedRandoms[proposalId][voter] = requestFlagedRandomness();

        return votes;
    }

    /**
     * @notice View function which returns if an account is whitelisted
     * @param account Account to check white list status of
     * @return If the account is whitelisted
     */
    function isWhitelisted(address account) public view returns (bool) {
        return (whitelistAccountExpirations[account] > block.timestamp);
    }

    /**
      * @notice Admin function for setting the voting delay
      * @param newVotingDelay new voting delay, in blocks
      */
    function _setVotingDelay(uint newVotingDelay) external {
        require(msg.sender == admin, "GovernorCharlie::_setVotingDelay: admin only");
        require(newVotingDelay >= MIN_VOTING_DELAY && newVotingDelay <= MAX_VOTING_DELAY, "GovernorCharlie::_setVotingDelay: invalid voting delay");
        uint oldVotingDelay = votingDelay;
        votingDelay = newVotingDelay;

        emit VotingDelaySet(oldVotingDelay,votingDelay);
    }

    /**
      * @notice Admin function for setting the voting period
      * @param newVotingPeriod new voting period, in blocks
      */
    function _setVotingPeriod(uint newVotingPeriod) external {
        require(msg.sender == admin, "GovernorCharlie::_setVotingPeriod: admin only");
        require(newVotingPeriod >= MIN_VOTING_PERIOD && newVotingPeriod <= MAX_VOTING_PERIOD, "GovernorCharlie::_setVotingPeriod: invalid voting period");
        uint oldVotingPeriod = votingPeriod;
        votingPeriod = newVotingPeriod;

        emit VotingPeriodSet(oldVotingPeriod, votingPeriod);
    }

    /**
      * @notice Admin function for setting the aggregating period
      * @param newAggregatingPeriod new aggregating period, in blocks
      */
    function _setAggregatingPeriod(uint newAggregatingPeriod) external {
        require(msg.sender == admin, "GovernorCharlie::_setAggregatingPeriod: admin only");
        require(newAggregatingPeriod >= MIN_AGGREGATING_PERIOD && newAggregatingPeriod <= MAX_AGGREGATING_PERIOD, "GovernorCharlie::_setAggregatingPeriod: invalid aggregating period");
        uint oldAggregatingPeriod = aggregatingPeriod;
        aggregatingPeriod = newAggregatingPeriod;

        emit AggregatingPeriodSet(oldAggregatingPeriod, aggregatingPeriod);
    }

    /**
      * @notice Admin function for setting the proposal threshold
      * @dev newProposalThreshold must be greater than the hardcoded min
      * @param newProposalThreshold new proposal threshold
      */
    function _setProposalThreshold(uint newProposalThreshold) external {
        require(msg.sender == admin, "GovernorCharlie::_setProposalThreshold: admin only");
        require(newProposalThreshold >= MIN_PROPOSAL_THRESHOLD && newProposalThreshold <= MAX_PROPOSAL_THRESHOLD, "GovernorCharlie::_setProposalThreshold: invalid proposal threshold");
        uint oldProposalThreshold = proposalThreshold;
        proposalThreshold = newProposalThreshold;

        emit ProposalThresholdSet(oldProposalThreshold, proposalThreshold);
    }

    /**
     * @notice Admin function for setting the whitelist expiration as a timestamp for an account. Whitelist status allows accounts to propose without meeting threshold
     * @param account Account address to set whitelist expiration for
     * @param expiration Expiration for account whitelist status as timestamp (if now < expiration, whitelisted)
     */
    function _setWhitelistAccountExpiration(address account, uint expiration) external {
        require(msg.sender == admin || msg.sender == whitelistGuardian, "GovernorCharlie::_setWhitelistAccountExpiration: admin only");
        whitelistAccountExpirations[account] = expiration;

        emit WhitelistAccountExpirationSet(account, expiration);
    }

    /**
     * @notice Admin function for setting the whitelistGuardian. WhitelistGuardian can cancel proposals from whitelisted addresses
     * @param account Account to set whitelistGuardian to (0x0 to remove whitelistGuardian)
     */
     function _setWhitelistGuardian(address account) external {
        require(msg.sender == admin, "GovernorCharlie::_setWhitelistGuardian: admin only");
        address oldGuardian = whitelistGuardian;
        whitelistGuardian = account;

        emit WhitelistGuardianSet(oldGuardian, whitelistGuardian);
     }

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function _setPendingAdmin(address newPendingAdmin) external {
        // Check caller = admin
        require(msg.sender == admin, "GovernorCharlie:_setPendingAdmin: admin only");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      */
    function _acceptAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && msg.sender != address(0), "GovernorCharlie:_acceptAdmin: pending admin only");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }
}

/** 
 * @dev Computes sqrt of `x`
 */
function sqrt(uint96 x) pure returns(uint96 y) {
    uint96 z = x + 1;
    z /= 2;

    y = x;
    while (z < y) {
        y = z;
        z = x / z + z;
        z /= 2;
    }
}
