## `GovernorCharlieDelegate`






### `feeUpdate(uint256 newFee)` (public)





### `eUpdate(uint32 newExpN, uint32 newExpD)` (public)





### `requestFlagedRandomness() → bytes32 requestId` (public)

Chainlink: Requests randomness



### `fulfillRandomness(bytes32 requestId, uint256 randomness)` (internal)

Chainlink: Callback function used by VRF Coordinator



### `initialize(address timelock_, address comp_, uint256 votingPeriod_, uint256 votingDelay_, uint256 proposalThreshold_)` (public)

Used to initialize the contract during delegator contructor




### `propose(address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, string description) → uint256` (public)

Function used to propose a new proposal. Sender must have delegates above the proposal threshold




### `queue(uint256 proposalId)` (external)

Queues a proposal of state succeeded




### `queueOrRevertInternal(address target, uint256 value, string signature, bytes data, uint256 eta)` (internal)





### `execute(uint256 proposalId)` (external)

Executes a queued proposal if eta has passed




### `cancel(uint256 proposalId)` (external)

Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold




### `getActions(uint256 proposalId) → address[] targets, uint256[] values, string[] signatures, bytes[] calldatas` (external)

Gets actions of a proposal




### `getReceipt(uint256 proposalId, address voter) → struct GovernorCharlieDelegateStorageV1.Receipt` (external)

Gets the receipt for a voter on a given proposal




### `pqvExpect(uint256 proposalId) → bool isSucceeded, uint256 aggregatedForVotes, uint256 aggregatedAgainstVotes, uint256 aggregatedAbstainVotes` (public)

Gets the expectation value



### `state(uint256 proposalId) → enum GovernorCharlieDelegateStorageV1.ProposalState` (public)

Gets the state of a proposal




### `pqvInternal(uint256 proposalId) → bool` (internal)





### `requestBaseFlagedRandom(uint256 proposalId)` (external)

Request base random



### `finalize(uint256 proposalId)` (external)

Finalize active state for pqv round



### `castVote(uint256 proposalId, uint8 support)` (external)

Cast a vote for a proposal




### `castVoteWithReason(uint256 proposalId, uint8 support, string reason)` (external)

Cast a vote for a proposal with a reason




### `castVoteBySig(uint256 proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s)` (external)

Cast a vote for a proposal by signature


External function that accepts EIP-712 signatures for voting on proposals.

### `castVoteInternal(address voter, uint256 proposalId, uint8 support) → uint96` (internal)

Internal function that caries out voting logic




### `isWhitelisted(address account) → bool` (public)

View function which returns if an account is whitelisted




### `_setVotingDelay(uint256 newVotingDelay)` (external)

Admin function for setting the voting delay




### `_setVotingPeriod(uint256 newVotingPeriod)` (external)

Admin function for setting the voting period




### `_setProposalThreshold(uint256 newProposalThreshold)` (external)

Admin function for setting the proposal threshold


newProposalThreshold must be greater than the hardcoded min


### `_setWhitelistAccountExpiration(address account, uint256 expiration)` (external)

Admin function for setting the whitelist expiration as a timestamp for an account. Whitelist status allows accounts to propose without meeting threshold




### `_setWhitelistGuardian(address account)` (external)

Admin function for setting the whitelistGuardian. WhitelistGuardian can cancel proposals from whitelisted addresses




### `_setPendingAdmin(address newPendingAdmin)` (external)

Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.


Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.


### `_acceptAdmin()` (external)

Accepts transfer of admin rights. msg.sender must be pendingAdmin


Admin function for pending admin to accept role and update admin




