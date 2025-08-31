// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IMarketplace.sol";
import "../token/NativeToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Escrow is IEscrow, Ownable, ReentrancyGuard {
    NativeToken public immutable nativeToken;
    address public marketplaceCore;
    address public disputeResolution;
    
    struct EscrowData {
        address buyer;
        address seller;
        uint256 amount;
        EscrowStatus status;
        uint256 createdAt;
    }
    
    mapping(uint256 => EscrowData) public escrows;
    
    event FundsLocked(uint256 indexed transactionId, address indexed buyer, address indexed seller, uint256 amount);
    event FundsReleased(uint256 indexed transactionId, address indexed seller, uint256 amount);
    event FundsRefunded(uint256 indexed transactionId, address indexed buyer, uint256 amount);
    event DisputeStarted(uint256 indexed transactionId);
    
    modifier onlyMarketplace() {
        require(msg.sender == marketplaceCore, "Only marketplace can call");
        _;
    }
    
    modifier onlyDisputeResolution() {
        require(msg.sender == disputeResolution, "Only dispute resolution can call");
        _;
    }
    
    modifier onlyAuthorized() {
        require(msg.sender == marketplaceCore || msg.sender == disputeResolution, "Not authorized");
        _;
    }
    
    constructor(address _nativeToken) Ownable(msg.sender) {
        nativeToken = NativeToken(_nativeToken);
    }
    
    function setMarketplaceCore(address _marketplace) external onlyOwner {
        require(_marketplace != address(0), "Invalid marketplace address");
        marketplaceCore = _marketplace;
    }
    
    function setDisputeResolution(address _disputeResolution) external onlyOwner {
        require(_disputeResolution != address(0), "Invalid dispute resolution address");
        disputeResolution = _disputeResolution;
    }
    
    function lockFunds(
        uint256 transactionId,
        address buyer,
        address seller,
        uint256 amount
    ) external override onlyMarketplace {
        require(buyer != address(0) && seller != address(0), "Invalid addresses");
        require(amount > 0, "Invalid amount");
        require(escrows[transactionId].amount == 0, "Funds already locked");
        
        escrows[transactionId] = EscrowData({
            buyer: buyer,
            seller: seller,
            amount: amount,
            status: EscrowStatus.Locked,
            createdAt: block.timestamp
        });
        
        emit FundsLocked(transactionId, buyer, seller, amount);
    }
    
    function releaseFunds(uint256 transactionId) external override onlyAuthorized nonReentrant {
        EscrowData storage escrowData = escrows[transactionId];
        require(escrowData.status == EscrowStatus.Locked, "Funds not locked");
        require(escrowData.amount > 0, "No funds to release");
        
        address seller = escrowData.seller;
        uint256 amount = escrowData.amount;
        
        escrowData.status = EscrowStatus.Released;
        
        require(nativeToken.transfer(seller, amount), "Transfer failed");
        
        emit FundsReleased(transactionId, seller, amount);
    }
    
    function refundBuyer(uint256 transactionId) external override onlyAuthorized nonReentrant {
        EscrowData storage escrowData = escrows[transactionId];
        require(escrowData.status == EscrowStatus.Locked || escrowData.status == EscrowStatus.Disputed, "Invalid status");
        require(escrowData.amount > 0, "No funds to refund");
        
        address buyer = escrowData.buyer;
        uint256 amount = escrowData.amount;
        
        escrowData.status = EscrowStatus.Refunded;
        
        require(nativeToken.transfer(buyer, amount), "Transfer failed");
        
        emit FundsRefunded(transactionId, buyer, amount);
    }
    
    function markDisputed(uint256 transactionId) external onlyDisputeResolution {
        EscrowData storage escrowData = escrows[transactionId];
        require(escrowData.status == EscrowStatus.Locked, "Funds not locked");
        
        escrowData.status = EscrowStatus.Disputed;
        
        emit DisputeStarted(transactionId);
    }
    
    function getEscrowBalance(uint256 transactionId) external view override returns (uint256) {
        return escrows[transactionId].amount;
    }
    
    function getEscrowStatus(uint256 transactionId) external view override returns (EscrowStatus) {
        return escrows[transactionId].status;
    }
    
    function getEscrowData(uint256 transactionId) external view returns (EscrowData memory) {
        return escrows[transactionId];
    }
    
    // Emergency functions
    function emergencyRelease(uint256 transactionId) external onlyOwner {
        EscrowData storage escrowData = escrows[transactionId];
        require(escrowData.status == EscrowStatus.Locked, "Invalid status");
        require(block.timestamp > escrowData.createdAt + 90 days, "Too early for emergency release");
        
        address seller = escrowData.seller;
        uint256 amount = escrowData.amount;
        
        escrowData.status = EscrowStatus.Released;
        
        require(nativeToken.transfer(seller, amount), "Transfer failed");
        
        emit FundsReleased(transactionId, seller, amount);
    }
    
    function emergencyRefund(uint256 transactionId) external onlyOwner {
        EscrowData storage escrowData = escrows[transactionId];
        require(escrowData.status == EscrowStatus.Locked, "Invalid status");
        require(block.timestamp > escrowData.createdAt + 90 days, "Too early for emergency refund");
        
        address buyer = escrowData.buyer;
        uint256 amount = escrowData.amount;
        
        escrowData.status = EscrowStatus.Refunded;
        
        require(nativeToken.transfer(buyer, amount), "Transfer failed");
        
        emit FundsRefunded(transactionId, buyer, amount);
    }
}
