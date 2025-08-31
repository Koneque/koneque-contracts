// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IDispute.sol";
import "../interfaces/IMarketplace.sol";
import "../token/NativeToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DisputeResolution is IDisputeResolution, Ownable, ReentrancyGuard {
    uint256 private _disputeIdCounter;
    
    NativeToken public immutable nativeToken;
    address public oracleRegistry;
    address public escrowContract;
    address public marketplaceCore;
    
    uint256 public constant DISPUTE_TIMEOUT = 7 days;
    uint256 public constant EVIDENCE_PERIOD = 3 days;
    uint256 public constant ORACLE_COUNT = 5;
    
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => mapping(address => DisputeDecision)) public oracleVotes;
    mapping(uint256 => mapping(DisputeDecision => uint256)) public voteCount;
    mapping(uint256 => string[]) public evidenceURIs;
    
    event DisputeRaised(uint256 indexed disputeId, uint256 indexed transactionId, address indexed initiator, string reason);
    event EvidenceSubmitted(uint256 indexed disputeId, address indexed submitter, string evidenceURI);
    event OraclesAssigned(uint256 indexed disputeId, address[] oracles);
    event VerdictSubmitted(uint256 indexed disputeId, address indexed oracle, DisputeDecision decision);
    event DisputeResolved(uint256 indexed disputeId, DisputeDecision decision);
    
    modifier onlyOracle(uint256 disputeId) {
        require(isAssignedOracle(disputeId, msg.sender), "Not an assigned oracle");
        _;
    }
    
    constructor(address _nativeToken) Ownable(msg.sender) {
        nativeToken = NativeToken(_nativeToken);
    }
    
    function setOracleRegistry(address _oracleRegistry) external onlyOwner {
        require(_oracleRegistry != address(0), "Invalid oracle registry address");
        oracleRegistry = _oracleRegistry;
    }
    
    function setEscrowContract(address _escrow) external onlyOwner {
        require(_escrow != address(0), "Invalid escrow address");
        escrowContract = _escrow;
    }
    
    function setMarketplaceCore(address _marketplace) external onlyOwner {
        require(_marketplace != address(0), "Invalid marketplace address");
        marketplaceCore = _marketplace;
    }
    
    function raiseDispute(uint256 transactionId, string calldata reason) external override returns (uint256) {
        require(bytes(reason).length > 0, "Reason required");
        
        // Verify transaction exists and caller is involved
        // This would require integration with marketplace to get transaction details
        require(isTransactionParticipant(transactionId, msg.sender), "Not a transaction participant");
        
        _disputeIdCounter++;
        uint256 newDisputeId = _disputeIdCounter;
        
        disputes[newDisputeId] = Dispute({
            id: newDisputeId,
            transactionId: transactionId,
            initiator: msg.sender,
            reason: reason,
            status: DisputeStatus.Active,
            decision: DisputeDecision.Pending,
            createdAt: block.timestamp,
            resolvedAt: 0,
            assignedOracles: new address[](0)
        });
        
        // Mark escrow as disputed
        IEscrow(escrowContract).markDisputed(transactionId);
        
        emit DisputeRaised(newDisputeId, transactionId, msg.sender, reason);
        
        // Auto-assign oracles
        assignOracles(transactionId);
        
        return newDisputeId;
    }
    
    function submitEvidence(uint256 transactionId, string calldata evidenceURI) external override {
        uint256 disputeId = getDisputeIdByTransaction(transactionId);
        require(disputeId > 0, "No active dispute");
        require(disputes[disputeId].status == DisputeStatus.Active, "Dispute not active");
        require(block.timestamp <= disputes[disputeId].createdAt + EVIDENCE_PERIOD, "Evidence period ended");
        require(isTransactionParticipant(transactionId, msg.sender), "Not a transaction participant");
        
        evidenceURIs[disputeId].push(evidenceURI);
        
        emit EvidenceSubmitted(disputeId, msg.sender, evidenceURI);
    }
    
    function assignOracles(uint256 transactionId) public override {
        uint256 disputeId = getDisputeIdByTransaction(transactionId);
        require(disputeId > 0, "No dispute found");
        require(disputes[disputeId].assignedOracles.length == 0, "Oracles already assigned");
        require(oracleRegistry != address(0), "Oracle registry not set");
        
        address[] memory selectedOracles = IOracleRegistry(oracleRegistry).selectOracles(transactionId, ORACLE_COUNT);
        disputes[disputeId].assignedOracles = selectedOracles;
        
        emit OraclesAssigned(disputeId, selectedOracles);
    }
    
    function submitVerdict(
        uint256 transactionId,
        DisputeDecision decision,
        string calldata reasoning
    ) external override {
        uint256 disputeId = getDisputeIdByTransaction(transactionId);
        require(disputeId > 0, "No dispute found");
        require(disputes[disputeId].status == DisputeStatus.Active, "Dispute not active");
        require(decision != DisputeDecision.Pending, "Invalid decision");
        require(!hasVoted[disputeId][msg.sender], "Already voted");
        require(isAssignedOracle(disputeId, msg.sender), "Not assigned oracle");
        
        hasVoted[disputeId][msg.sender] = true;
        oracleVotes[disputeId][msg.sender] = decision;
        voteCount[disputeId][decision]++;
        
        emit VerdictSubmitted(disputeId, msg.sender, decision);
        
        // Check if we have enough votes to finalize
        if (canFinalize(disputeId)) {
            finalizeDispute(transactionId);
        }
    }
    
    function finalizeDispute(uint256 transactionId) public override {
        uint256 disputeId = getDisputeIdByTransaction(transactionId);
        require(disputeId > 0, "No dispute found");
        require(disputes[disputeId].status == DisputeStatus.Active, "Dispute not active");
        require(canFinalize(disputeId), "Cannot finalize yet");
        
        Dispute storage dispute = disputes[disputeId];
        
        // Determine majority decision
        DisputeDecision finalDecision;
        if (voteCount[disputeId][DisputeDecision.FavorBuyer] > voteCount[disputeId][DisputeDecision.FavorSeller]) {
            finalDecision = DisputeDecision.FavorBuyer;
        } else {
            finalDecision = DisputeDecision.FavorSeller;
        }
        
        dispute.decision = finalDecision;
        dispute.status = DisputeStatus.Resolved;
        dispute.resolvedAt = block.timestamp;
        
        // Execute decision
        if (finalDecision == DisputeDecision.FavorBuyer) {
            IEscrow(escrowContract).refundBuyer(transactionId);
        } else {
            IEscrow(escrowContract).releaseFunds(transactionId);
        }
        
        // Update oracle reputations
        updateOracleReputations(disputeId, finalDecision);
        
        emit DisputeResolved(disputeId, finalDecision);
    }
    
    function getDisputeDetails(uint256 disputeId) external view override returns (Dispute memory) {
        return disputes[disputeId];
    }

    function getAssignedOracles(uint256 disputeId) external view returns (address[] memory) {
        return disputes[disputeId].assignedOracles;
    }
    
    function getEvidenceURIs(uint256 disputeId) external view returns (string[] memory) {
        return evidenceURIs[disputeId];
    }
    
    function getDisputeVotes(uint256 disputeId) external view returns (
        uint256 favorBuyerVotes,
        uint256 favorSellerVotes,
        uint256 totalVotes
    ) {
        favorBuyerVotes = voteCount[disputeId][DisputeDecision.FavorBuyer];
        favorSellerVotes = voteCount[disputeId][DisputeDecision.FavorSeller];
        totalVotes = favorBuyerVotes + favorSellerVotes;
    }
    
    // Internal functions
    function isTransactionParticipant(uint256 transactionId, address user) internal view returns (bool) {
        // This would integrate with marketplace to verify user is buyer or seller
        // Simplified implementation
        return true;
    }
    
    function getDisputeIdByTransaction(uint256 transactionId) internal view returns (uint256) {
        // Find dispute by transaction ID - in production, use a mapping
        uint256 totalDisputes = _disputeIdCounter;
        for (uint256 i = 1; i <= totalDisputes; i++) {
            if (disputes[i].transactionId == transactionId && disputes[i].status == DisputeStatus.Active) {
                return i;
            }
        }
        return 0;
    }
    
    function isAssignedOracle(uint256 disputeId, address oracle) internal view returns (bool) {
        address[] memory assigned = disputes[disputeId].assignedOracles;
        for (uint256 i = 0; i < assigned.length; i++) {
            if (assigned[i] == oracle) {
                return true;
            }
        }
        return false;
    }
    
    function canFinalize(uint256 disputeId) internal view returns (bool) {
        uint256 totalVotes = voteCount[disputeId][DisputeDecision.FavorBuyer] + 
                            voteCount[disputeId][DisputeDecision.FavorSeller];
        return totalVotes >= (ORACLE_COUNT / 2 + 1); // Majority
    }
    
    function updateOracleReputations(uint256 disputeId, DisputeDecision finalDecision) internal {
        if (oracleRegistry == address(0)) return;
        
        address[] memory assigned = disputes[disputeId].assignedOracles;
        for (uint256 i = 0; i < assigned.length; i++) {
            address oracle = assigned[i];
            if (hasVoted[disputeId][oracle]) {
                bool correctDecision = oracleVotes[disputeId][oracle] == finalDecision;
                IOracleRegistry(oracleRegistry).updateReputation(oracle, correctDecision);
                
                if (correctDecision) {
                    IOracleRegistry(oracleRegistry).rewardOracle(oracle, 1000 * 10**18); // 1000 tokens
                } else {
                    IOracleRegistry(oracleRegistry).slashOracle(oracle, 500 * 10**18); // 500 tokens penalty
                }
            }
        }
    }
}
