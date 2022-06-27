## `GovernorCharlieDelegator`






### `constructor(address timelock_, address comp_, address admin_, address implementation_, uint256 votingPeriod_, uint256 votingDelay_, uint256 proposalThreshold_)` (public)





### `_setImplementation(address implementation_)` (public)

Called by the admin to update the implementation of the delegator




### `delegateTo(address callee, bytes data)` (internal)

Internal method to delegate execution to another contract


It returns to the external caller whatever the implementation returns or forwards reverts


### `fallback()` (external)



Delegates execution to an implementation contract.
It returns to the external caller whatever the implementation returns
or forwards reverts.


