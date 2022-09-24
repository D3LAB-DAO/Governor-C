// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../governance/GovernorCharlieDelegate.sol";

contract Funding is GovernorCharlieDelegate {
    event SetRound(uint256 indexed rid);
    event AddItem(address indexed grantee, uint256 rid, uint256 indexed iid);

    event DoFunding(address indexed grantor, uint256 amount, uint256 rid);
    event DoRefunding(address indexed grantor, uint256 amount, uint256 rid);
    event Claim(address indexed grantee, uint256 rid, uint256 indexed iid);

    // TODO: max and min
    /// @notice The round period
    uint256 public constant ROUND_TIME = ONE_DAY_BLOCKS * 30; // About 1 month

    // TODO: max and min
    /// @notice The claimable period
    uint256 public constant CLAIM_TIME = ONE_DAY_BLOCKS * 30; // About 1 month

    struct Grantee {
        address account;
        bytes data;
        bool granted;
    }

    mapping(uint256 => Grantee) public grantees;

    struct Round {
        uint256 start;
        // uint256 end;
        uint256[] iids;
        uint256 totalAmounts;
        uint256 denominator;
    }

    mapping(uint256 => Round) public rounds;
    uint256 public rid;

    mapping(address => uint256) public amounts;

    function setRound() public returns (uint256) {
        require(msg.sender == admin, "Funding::setRound: admin only");
        require(
            rounds[rid].start + ROUND_TIME + CLAIM_TIME < block.timestamp,
            "Funding::setRound: one live round"
        );

        rid++;
        Round storage round = rounds[rid];
        round.start = block.timestamp;

        emit SetRound(rid);
        return rid;
    }

    function validRound() public view returns (bool) {
        return
            (rounds[rid].start < block.timestamp) &&
            (rounds[rid].start + ROUND_TIME > block.timestamp);
    }

    function claimable() public view returns (bool) {
        return
            (rounds[rid].start + ROUND_TIME < block.timestamp) &&
            (rounds[rid].start + ROUND_TIME + CLAIM_TIME > block.timestamp);
    }

    function addItem(address grantee, bytes memory data)
        public
        returns (uint256)
    {
        require(isWhitelisted(msg.sender), "Funding::addItem: whitelist only");
        require(validRound(), "Funding::addItem: round does not open yet");
        require(
            grantee != address(0),
            "Funding::addItem: address zero not allowed"
        );

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        string[] memory signatures = new string[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "";
        targets[0] = address(this);
        values[0] = 0;
        signatures[0] = "claim";
        calldatas[0] = abi.encodePacked(proposalCount + 1);

        uint256 iid = propose(
            targets,
            values,
            signatures,
            calldatas,
            description
        );
        require(
            proposals[proposalCount].endBlock < rounds[rid].start + ROUND_TIME,
            "Funding::addItem: endBlock exceeds valid range"
        );

        grantees[iid] = Grantee({account: grantee, data: data, granted: false});
        rounds[rid].iids.push(iid);

        emit AddItem(grantee, rid, iid);
        return iid;
    }

    function funding() public payable returns (uint256) {
        require(validRound(), "Funding::funding: round does not open yet");
        require(msg.value > 0);
        amounts[msg.sender] += msg.value;
        rounds[rid].totalAmounts += msg.value;

        emit DoFunding(msg.sender, msg.value, rid);
        return rid;
    }

    function refunding(uint256 amount) public returns (uint256) {
        require(validRound(), "Funding::refunding: round already closed");
        require(
            amounts[msg.sender] >= amount,
            "Funding::refunding: not enough amount"
        );
        amounts[msg.sender] -= amount;
        rounds[rid].totalAmounts -= amount;
        (bool succeed, ) = msg.sender.call{value: amount}("");
        require(succeed, "Funding::refunding: transfer error");

        emit DoRefunding(msg.sender, amount, rid);
        return rid;
    }

    receive() external payable {
        (bool succeed, ) = msg.sender.call{value: msg.value}("");
        require(succeed, "Funding::refunding: transfer error");
    }

    function poolAmount() public view returns (uint256) {
        return rounds[rid].totalAmounts;
    }

    function _denominator(uint256 rid_) internal returns (uint256 denominator) {
        Round storage round = rounds[rid_];

        if (round.denominator != 0) {
            return round.denominator;
        }

        // else
        for (uint256 i = 0; i < round.iids.length; i++) {
            uint256 iid = round.iids[i];

            if (
                state(iid) == ProposalState.Succeeded ||
                state(iid) == ProposalState.Queued ||
                state(iid) == ProposalState.Executed
            ) {
                denominator += pqvMetas[round.iids[i]].aggregatedForVotes;
            }
        }
        round.denominator = denominator;
    }

    function claim(uint256 iid) external {
        require(claimable(), "Funding::claim: claim does not valid yet");
        require(
            msg.sender == address(timelock),
            "Funding::withdraw: caller should be timelock"
        );

        Round storage round = rounds[rid];
        Grantee storage grantee = grantees[iid];

        require(!grantee.granted, "Funding::claim: already granted");

        uint256 amount = (round.totalAmounts *
            pqvMetas[round.iids[iid]].aggregatedForVotes) / _denominator(rid);
        (bool succeed, ) = grantee.account.call{value: amount}(grantee.data);
        require(succeed, "Funding::claim: transfer error");

        grantee.granted = true;

        emit Claim(grantee.account, rid, iid);
    }
}
