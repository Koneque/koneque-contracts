// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IReferralSystem {
    struct ReferralData {
        address referrer;
        address referred;
        uint256 registeredAt;
        bool rewardClaimed;
        uint256 firstPurchaseAmount;
    }

    function registerReferral(address referrer, address referred) external;
    function claimReferralReward(address referred) external;
    function setReferralRate(uint256 newRate) external;
    function getReferralStats(address referrer) external view returns (uint256 totalReferrals, uint256 totalRewards);
    function validateReferralEligibility(address referred) external view returns (bool);
}
