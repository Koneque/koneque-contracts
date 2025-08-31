// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IReferral.sol";
import "../interfaces/IMarketplace.sol";
import "../token/NativeToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ReferralSystem is IReferralSystem, Ownable, ReentrancyGuard {
    NativeToken public immutable nativeToken;
    address public feeManager;
    address public marketplaceCore;
    
    uint256 public referralRate = 500; // 5% in basis points
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant MIN_PURCHASE_AMOUNT = 100 * 10**18; // 100 tokens minimum
    
    mapping(address => ReferralData) public referrals;
    mapping(address => address[]) public referrerToReferred;
    mapping(address => uint256) public referrerTotalRewards;
    mapping(address => uint256) public referrerTotalReferrals;
    
    event ReferralRegistered(address indexed referrer, address indexed referred);
    event ReferralRewardClaimed(address indexed referrer, address indexed referred, uint256 amount);
    event ReferralRateUpdated(uint256 oldRate, uint256 newRate);
    
    modifier onlyFeeManager() {
        require(msg.sender == feeManager, "Only fee manager can call");
        _;
    }
    
    constructor(address _nativeToken) Ownable(msg.sender) {
        nativeToken = NativeToken(_nativeToken);
    }
    
    function setFeeManager(address _feeManager) external onlyOwner {
        require(_feeManager != address(0), "Invalid fee manager address");
        feeManager = _feeManager;
    }
    
    function setMarketplaceCore(address _marketplace) external onlyOwner {
        require(_marketplace != address(0), "Invalid marketplace address");
        marketplaceCore = _marketplace;
    }
    
    function registerReferral(address referrer, address referred) external override {
        require(referrer != address(0), "Invalid referrer");
        require(referred != address(0), "Invalid referred");
        require(referrer != referred, "Cannot refer yourself");
        require(referrals[referred].referrer == address(0), "Already has referrer");
        require(msg.sender == referred || msg.sender == owner(), "Not authorized");
        
        referrals[referred] = ReferralData({
            referrer: referrer,
            referred: referred,
            registeredAt: block.timestamp,
            rewardClaimed: false,
            firstPurchaseAmount: 0
        });
        
        referrerToReferred[referrer].push(referred);
        
        emit ReferralRegistered(referrer, referred);
    }
    
    function claimReferralReward(address referred) external override nonReentrant {
        ReferralData storage referralData = referrals[referred];
        require(referralData.referrer != address(0), "No referrer found");
        require(!referralData.rewardClaimed, "Reward already claimed");
        require(referralData.firstPurchaseAmount >= MIN_PURCHASE_AMOUNT, "Purchase amount too low");
        require(msg.sender == referralData.referrer, "Not the referrer");
        
        uint256 rewardAmount = (referralData.firstPurchaseAmount * referralRate) / BASIS_POINTS;
        
        referralData.rewardClaimed = true;
        referrerTotalRewards[referralData.referrer] += rewardAmount;
        referrerTotalReferrals[referralData.referrer]++;
        
        // Request reward from fee manager
        IFeeManager(feeManager).processReferralReward(referralData.referrer, rewardAmount);
        
        emit ReferralRewardClaimed(referralData.referrer, referred, rewardAmount);
    }
    
    function setReferralRate(uint256 newRate) external override onlyOwner {
        require(newRate <= 2000, "Rate cannot exceed 20%"); // Max 20%
        
        uint256 oldRate = referralRate;
        referralRate = newRate;
        
        emit ReferralRateUpdated(oldRate, newRate);
    }
    
    function getReferralStats(address referrer) external view override returns (uint256 totalReferrals, uint256 totalRewards) {
        totalReferrals = referrerTotalReferrals[referrer];
        totalRewards = referrerTotalRewards[referrer];
    }
    
    function validateReferralEligibility(address referred) external view override returns (bool) {
        ReferralData memory referralData = referrals[referred];
        return referralData.referrer != address(0) && !referralData.rewardClaimed;
    }
    
    function recordFirstPurchase(address buyer, uint256 amount) external {
        require(msg.sender == marketplaceCore, "Only marketplace can call");
        
        ReferralData storage referralData = referrals[buyer];
        if (referralData.referrer != address(0) && referralData.firstPurchaseAmount == 0) {
            referralData.firstPurchaseAmount = amount;
        }
    }
    
    function getReferralData(address referred) external view returns (ReferralData memory) {
        return referrals[referred];
    }
    
    function getReferredUsers(address referrer) external view returns (address[] memory) {
        return referrerToReferred[referrer];
    }
    
    function getPendingReward(address referred) external view returns (uint256) {
        ReferralData memory referralData = referrals[referred];
        if (referralData.referrer == address(0) || referralData.rewardClaimed || referralData.firstPurchaseAmount == 0) {
            return 0;
        }
        
        if (referralData.firstPurchaseAmount < MIN_PURCHASE_AMOUNT) {
            return 0;
        }
        
        return (referralData.firstPurchaseAmount * referralRate) / BASIS_POINTS;
    }
    
    function isEligibleForReward(address referred) external view returns (bool) {
        ReferralData memory referralData = referrals[referred];
        return referralData.referrer != address(0) && 
               !referralData.rewardClaimed && 
               referralData.firstPurchaseAmount >= MIN_PURCHASE_AMOUNT;
    }
    
    function getActiveReferralsCount(address referrer) external view returns (uint256) {
        address[] memory referred = referrerToReferred[referrer];
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < referred.length; i++) {
            ReferralData memory referralData = referrals[referred[i]];
            if (!referralData.rewardClaimed && referralData.firstPurchaseAmount > 0) {
                activeCount++;
            }
        }
        
        return activeCount;
    }
    
    function getReferrerOf(address referred) external view returns (address) {
        return referrals[referred].referrer;
    }
    
    function updateMinPurchaseAmount(uint256 newAmount) external onlyOwner {
        require(newAmount > 0, "Invalid amount");
        // Update minimum purchase amount for referral eligibility
    }
    
    // Emergency function to recover tokens
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(amount <= nativeToken.balanceOf(address(this)), "Insufficient balance");
        require(nativeToken.transfer(owner(), amount), "Transfer failed");
    }
}
