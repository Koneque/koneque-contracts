// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IMarketplace.sol";
import "../interfaces/IReferral.sol";
import "../token/NativeToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract FeeManager is IFeeManager, Ownable, ReentrancyGuard {
    NativeToken public immutable nativeToken;
    address public marketplaceCore;
    address public referralSystem;
    address public platformWallet;
    
    // Fee rates in basis points (1% = 100 bp)
    mapping(FeeType => uint256) public feeRates;
    
    uint256 public constant MAX_FEE_RATE = 1000; // 10% maximum
    uint256 public constant BASIS_POINTS = 10000;
    
    uint256 public platformFeesAccumulated;
    
    event FeesCalculated(uint256 indexed transactionId, FeeType feeType, uint256 amount, uint256 fees);
    event FeesDistributed(uint256 indexed transactionId, uint256 platformFee, uint256 referralFee);
    event FeeRateUpdated(FeeType feeType, uint256 oldRate, uint256 newRate);
    event PlatformFeesCollected(address indexed recipient, uint256 amount);
    event ReferralRewardProcessed(address indexed referrer, uint256 amount);
    
    modifier onlyMarketplace() {
        require(msg.sender == marketplaceCore, "Only marketplace can call");
        _;
    }
    
    constructor(address _nativeToken, address _platformWallet) Ownable(msg.sender) {
        nativeToken = NativeToken(_nativeToken);
        platformWallet = _platformWallet;
        
        // Initialize default fee rates
        feeRates[FeeType.Listing] = 50; // 0.5%
        feeRates[FeeType.Purchase] = 250; // 2.5%
        feeRates[FeeType.Referral] = 100; // 1% of purchase for referrer
    }
    
    function setMarketplaceCore(address _marketplace) external onlyOwner {
        require(_marketplace != address(0), "Invalid marketplace address");
        marketplaceCore = _marketplace;
    }
    
    function setReferralSystem(address _referralSystem) external onlyOwner {
        require(_referralSystem != address(0), "Invalid referral system address");
        referralSystem = _referralSystem;
    }
    
    function setPlatformWallet(address _platformWallet) external onlyOwner {
        require(_platformWallet != address(0), "Invalid platform wallet address");
        platformWallet = _platformWallet;
    }
    
    function calculateFees(uint256 amount, FeeType feeType) external view override returns (uint256) {
        return (amount * feeRates[feeType]) / BASIS_POINTS;
    }
    
    function distributeFees(uint256 transactionId, uint256 totalFees) external override onlyMarketplace nonReentrant {
        require(totalFees > 0, "No fees to distribute");
        
        // Get buyer address from marketplace (simplified - would need actual implementation)
        address buyer = msg.sender; // This would be extracted from transaction data
        
        uint256 referralFee = 0;
        uint256 platformFee = totalFees;
        
        // Check if buyer has a referrer
        if (referralSystem != address(0)) {
            // Get referrer from referral system
            try IReferralSystem(referralSystem).validateReferralEligibility(buyer) returns (bool hasReferrer) {
                if (hasReferrer) {
                    referralFee = (totalFees * feeRates[FeeType.Referral]) / feeRates[FeeType.Purchase];
                    platformFee = totalFees - referralFee;
                    
                    // Process referral reward would happen here
                    // This is a simplified version
                }
            } catch {
                // Continue without referral if system unavailable
            }
        }
        
        platformFeesAccumulated += platformFee;
        
        emit FeesDistributed(transactionId, platformFee, referralFee);
    }
    
    function setFeeRate(FeeType feeType, uint256 newRate) external override onlyOwner {
        require(newRate <= MAX_FEE_RATE, "Fee rate too high");
        
        uint256 oldRate = feeRates[feeType];
        feeRates[feeType] = newRate;
        
        emit FeeRateUpdated(feeType, oldRate, newRate);
    }
    
    function collectPlatformFees() external override nonReentrant {
        require(msg.sender == platformWallet || msg.sender == owner(), "Not authorized");
        require(platformFeesAccumulated > 0, "No fees to collect");
        
        uint256 amount = platformFeesAccumulated;
        platformFeesAccumulated = 0;
        
        require(nativeToken.transfer(platformWallet, amount), "Transfer failed");
        
        emit PlatformFeesCollected(platformWallet, amount);
    }
    
    function processReferralReward(address referrer, uint256 amount) external override {
        require(msg.sender == referralSystem, "Only referral system can call");
        require(referrer != address(0), "Invalid referrer");
        require(amount > 0, "Invalid amount");
        
        require(nativeToken.transfer(referrer, amount), "Transfer failed");
        
        emit ReferralRewardProcessed(referrer, amount);
    }
    
    function calculateNetAmount(uint256 grossAmount, FeeType feeType) external view returns (uint256 netAmount, uint256 fees) {
        fees = this.calculateFees(grossAmount, feeType);
        netAmount = grossAmount - fees;
    }
    
    function getFeeRate(FeeType feeType) external view returns (uint256) {
        return feeRates[feeType];
    }
    
    function getPlatformFeesAccumulated() external view returns (uint256) {
        return platformFeesAccumulated;
    }
    
    // Emergency function to recover tokens
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(amount <= nativeToken.balanceOf(address(this)), "Insufficient balance");
        require(nativeToken.transfer(owner(), amount), "Transfer failed");
    }
}
