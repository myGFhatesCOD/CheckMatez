// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommitmentLadder {
    struct Tier {
        uint256 unlockThreshold;
        string description;
    }

    Tier[] public tiers;
    mapping(address => uint256) public commitments;
    uint256 public totalCommitments;

    event TierUnlocked(address indexed user, uint256 tier);

    constructor() {
        // initialize commitment tiers
        tiers.push(Tier(1, "Tier 1: Basic Access"));
        tiers.push(Tier(5, "Tier 2: Intermediate Access"));
        tiers.push(Tier(10, "Tier 3: Advanced Access"));
        tiers.push(Tier(15, "Tier 4: Premium Access"));
        tiers.push(Tier(20, "Tier 5: Elite Access"));
    }

    function commit(uint256 amount) public {
        commitments[msg.sender] += amount;
        totalCommitments += amount;
        checkUnlock(msg.sender);
    }

    function checkUnlock(address user) internal {
        for (uint256 i = 0; i < tiers.length; i++) {
            if (commitments[user] >= tiers[i].unlockThreshold) {
                emit TierUnlocked(user, i + 1);
            }
        }
    }

    function getCommitment(address user) public view returns (uint256) {
        return commitments[user];
    }

    function getTotalCommitments() public view returns (uint256) {
        return totalCommitments;
    }
}
