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
    uint256 public constant DEFAULT_CODE_VALIDITY = 365 days; // 1 año por defecto
    uint256 public constant DEFAULT_REFERRAL_VALIDITY = 90 days; // 90 días para usar el referido
    
    mapping(address => ReferralData) public referrals;
    mapping(address => address[]) public referrerToReferred;
    mapping(address => uint256) public referrerTotalRewards;
    mapping(address => uint256) public referrerTotalReferrals;
    
    // New mappings for referral codes
    mapping(bytes32 => ReferralCode) public referralCodes;
    mapping(address => string[]) public userReferralCodes;
    
    event ReferralRegistered(address indexed referrer, address indexed referred);
    event ReferralRewardClaimed(address indexed referrer, address indexed referred, uint256 amount);
    event ReferralRateUpdated(uint256 oldRate, uint256 newRate);
    event ReferralCodeCreated(address indexed owner, string code, uint256 expiresAt);
    event ReferralCodeUsed(string code, address indexed referred);
    
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
    
    
    function createReferralCode(
        string calldata code, 
        uint256 validityPeriod, 
        uint256 maxUsage
    ) external override {
        require(bytes(code).length > 0, "Code cannot be empty");
        require(bytes(code).length <= 32, "Code too long");
        
        bytes32 codeHash = keccak256(abi.encodePacked(code));
        require(referralCodes[codeHash].owner == address(0), "Code already exists");
        require(validityPeriod > 0, "Invalid validity period");
        require(maxUsage > 0, "Invalid max usage");
        
        uint256 expiresAt = block.timestamp + validityPeriod;
        
        referralCodes[codeHash] = ReferralCode({
            owner: msg.sender,
            createdAt: block.timestamp,
            expiresAt: expiresAt,
            isActive: true,
            usageCount: 0,
            maxUsage: maxUsage
        });
        
        userReferralCodes[msg.sender].push(code);
        
        emit ReferralCodeCreated(msg.sender, code, expiresAt);
    }
    
    function _isReferralCodeValid(string calldata code) internal view returns (bool) {
        bytes32 codeHash = keccak256(abi.encodePacked(code));
        ReferralCode memory refCode = referralCodes[codeHash];
        return refCode.owner != address(0) && 
               refCode.isActive && 
               block.timestamp <= refCode.expiresAt &&
               refCode.usageCount < refCode.maxUsage;
    }
    
    function registerReferralWithCode(string calldata code, address referred) external override {
        require(referred != address(0), "Invalid referred address");
        require(referrals[referred].referrer == address(0), "Already has referrer");
        require(msg.sender == referred || msg.sender == owner(), "Not authorized");
        require(_isReferralCodeValid(code), "Invalid or expired code");
        
        ReferralCode storage refCode = referralCodes[keccak256(abi.encodePacked(code))];
        require(refCode.owner != referred, "Cannot use own code");
        require(refCode.usageCount < refCode.maxUsage, "Code usage limit reached");
        
        uint256 referralExpiresAt = block.timestamp + DEFAULT_REFERRAL_VALIDITY;
        
        referrals[referred] = ReferralData({
            referrer: refCode.owner,
            referred: referred,
            registeredAt: block.timestamp,
            expiresAt: referralExpiresAt,
            rewardClaimed: false,
            firstPurchaseAmount: 0,
            referralCode: code
        });
        
        refCode.usageCount++;
        referrerToReferred[refCode.owner].push(referred);
        
        emit ReferralCodeUsed(code, referred);
        emit ReferralRegistered(refCode.owner, referred);
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
        
        uint256 referralExpiresAt = block.timestamp + DEFAULT_REFERRAL_VALIDITY;
        
        referrals[referred] = ReferralData({
            referrer: referrer,
            referred: referred,
            registeredAt: block.timestamp,
            expiresAt: referralExpiresAt,
            rewardClaimed: false,
            firstPurchaseAmount: 0,
            referralCode: ""
        });
        
        referrerToReferred[referrer].push(referred);
        
        emit ReferralRegistered(referrer, referred);
    }
    
    function claimReferralReward(address referred) external override nonReentrant {
        ReferralData storage referralData = referrals[referred];
        require(referralData.referrer != address(0), "No referrer found");
        require(!referralData.rewardClaimed, "Reward already claimed");
        require(block.timestamp <= referralData.expiresAt, "Referral expired");
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
        return referralData.referrer != address(0) && 
               !referralData.rewardClaimed && 
               block.timestamp <= referralData.expiresAt;
    }
    
    function getReferralCodeInfo(string calldata code) external view override returns (ReferralCode memory) {
        return referralCodes[keccak256(abi.encodePacked(code))];
    }
    
    function isReferralCodeValid(string calldata code) external view override returns (bool) {
        return _isReferralCodeValid(code);
    }
    
    function recordFirstPurchase(address buyer, uint256 amount) external {
        require(msg.sender == marketplaceCore, "Only marketplace can call");
        
        ReferralData storage referralData = referrals[buyer];
        if (referralData.referrer != address(0) && 
            referralData.firstPurchaseAmount == 0 && 
            block.timestamp <= referralData.expiresAt) {
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
        if (referralData.referrer == address(0) || 
            referralData.rewardClaimed || 
            referralData.firstPurchaseAmount == 0 ||
            block.timestamp > referralData.expiresAt) {
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
               referralData.firstPurchaseAmount >= MIN_PURCHASE_AMOUNT &&
               block.timestamp <= referralData.expiresAt;
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
