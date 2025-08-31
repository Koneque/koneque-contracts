// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IReferralSystem {
    struct ReferralData {
        address referrer;
        address referred;
        uint256 registeredAt;
        uint256 expiresAt;
        bool rewardClaimed;
        uint256 firstPurchaseAmount;
        string referralCode;
    }

    struct ReferralCode {
        address owner;
        uint256 createdAt;
        uint256 expiresAt;
        bool isActive;
        uint256 usageCount;
        uint256 maxUsage;
    }

    function createReferralCode(string calldata code, uint256 validityPeriod, uint256 maxUsage) external;
    function registerReferralWithCode(string calldata code, address referred) external;
    function registerReferral(address referrer, address referred) external;
    function claimReferralReward(address referred) external;
    function setReferralRate(uint256 newRate) external;
    function getReferralStats(address referrer) external view returns (uint256 totalReferrals, uint256 totalRewards);
    function validateReferralEligibility(address referred) external view returns (bool);
    function getReferralCodeInfo(string calldata code) external view returns (ReferralCode memory);
    function isReferralCodeValid(string calldata code) external view returns (bool);
}
