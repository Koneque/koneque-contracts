// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDisputeResolution {
    enum DisputeStatus { Active, Resolved, Cancelled }
    enum DisputeDecision { Pending, FavorBuyer, FavorSeller }

    struct Dispute {
        uint256 id;
        uint256 transactionId;
        address initiator;
        string reason;
        DisputeStatus status;
        DisputeDecision decision;
        uint256 createdAt;
        uint256 resolvedAt;
        address[] assignedOracles;
    }

    function raiseDispute(uint256 transactionId, string calldata reason) external returns (uint256);
    function submitEvidence(uint256 transactionId, string calldata evidenceURI) external;
    function assignOracles(uint256 transactionId) external;
    function submitVerdict(uint256 transactionId, DisputeDecision decision, string calldata reasoning) external;
    function finalizeDispute(uint256 transactionId) external;
    function getDisputeDetails(uint256 transactionId) external view returns (Dispute memory);
}

interface IOracleRegistry {
    struct Oracle {
        address oracleAddress;
        uint256 stake;
        uint256 reputation;
        uint256 totalVotes;
        uint256 correctVotes;
        bool isActive;
        uint256 registeredAt;
    }

    function registerOracle(uint256 stake) external;
    function updateReputation(address oracle, bool correctDecision) external;
    function selectOracles(uint256 transactionId, uint256 count) external returns (address[] memory);
    function slashOracle(address oracle, uint256 amount) external;
    function rewardOracle(address oracle, uint256 amount) external;
    function getOracleStats(address oracle) external view returns (Oracle memory);
}
