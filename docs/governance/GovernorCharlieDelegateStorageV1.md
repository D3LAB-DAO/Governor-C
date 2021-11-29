## `GovernorCharlieDelegateStorageV1`

For future upgrades, do not change GovernorCharlieDelegateStorageV1. Create a new
contract which implements GovernorCharlieDelegateStorageV1 and following the naming convention
GovernorCharlieDelegateStorageVX.






### `FlagedRandom`


uint256 randomValue


uint256 returnTimestamp


### `Proposal`


uint256 id


address proposer


uint256 eta


address[] targets


uint256[] values


string[] signatures


bytes[] calldatas


uint256 startBlock


uint256 endBlock


bytes32 baseFlagedRandom


uint256 forVotes


uint256 againstVotes


uint256 abstainVotes


bool canceled


bool executed


uint256 finalizedTime


mapping(address => struct GovernorCharlieDelegateStorageV1.Receipt) receipts


### `Receipt`


bool hasVoted


uint8 support


uint96 votes


bytes32 myFlagedRandom



### `ProposalState`





























