## `GovernorCharlieEvents`







### `ProposalCreated(uint256 id, address proposer, address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, uint256 startBlock, uint256 endBlock, string description)`

An event emitted when a new proposal is created



### `VoteCast(address voter, uint256 proposalId, uint8 support, uint256 votes, string reason)`

An event emitted when a vote has been cast on a proposal




### `ProposalCanceled(uint256 id)`

An event emitted when a proposal has been canceled



### `ProposalFinalized(uint256 id)`

An event emitted when a proposal has been finalized



### `ProposalQueued(uint256 id, uint256 eta)`

An event emitted when a proposal has been queued in the Timelock



### `ProposalExecuted(uint256 id)`

An event emitted when a proposal has been executed in the Timelock



### `VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay)`

An event emitted when the voting delay is set



### `VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod)`

An event emitted when the voting period is set



### `NewImplementation(address oldImplementation, address newImplementation)`

Emitted when implementation is changed



### `ProposalThresholdSet(uint256 oldProposalThreshold, uint256 newProposalThreshold)`

Emitted when proposal threshold is set



### `NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin)`

Emitted when pendingAdmin is changed



### `NewAdmin(address oldAdmin, address newAdmin)`

Emitted when pendingAdmin is accepted, which means admin is updated



### `WhitelistAccountExpirationSet(address account, uint256 expiration)`

Emitted when whitelist account expiration is set



### `WhitelistGuardianSet(address oldGuardian, address newGuardian)`

Emitted when the whitelistGuardian is set





