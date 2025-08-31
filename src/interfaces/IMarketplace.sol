// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMarketplaceCore {
    struct Item {
        uint256 id;
        address seller;
        uint256 price;
        string metadataURI;
        string category;
        bool isActive;
        uint256 createdAt;
    }

    struct Transaction {
        uint256 id;
        uint256 itemId;
        address buyer;
        address seller;
        uint256 amount;
        uint256 timestamp;
        bool isConfirmed;
        bool isDisputed;
    }

    function listItem(uint256 price, string calldata metadataURI, string calldata category) external returns (uint256);
    function buyItem(uint256 itemId) external returns (uint256);
    function buyBatch(uint256[] calldata itemIds) external returns (uint256[] memory);
    function cancelListing(uint256 itemId) external;
    function confirmDelivery(uint256 transactionId) external;
    function getItemDetails(uint256 itemId) external view returns (Item memory);
    function getActiveListings() external view returns (Item[] memory);
}

interface IEscrow {
    enum EscrowStatus { Locked, Released, Refunded, Disputed }

    function lockFunds(uint256 transactionId, address buyer, address seller, uint256 amount) external;
    function releaseFunds(uint256 transactionId) external;
    function refundBuyer(uint256 transactionId) external;
    function markDisputed(uint256 transactionId) external;
    function getEscrowBalance(uint256 transactionId) external view returns (uint256);
    function getEscrowStatus(uint256 transactionId) external view returns (EscrowStatus);
}

interface IFeeManager {
    enum FeeType { Listing, Purchase, Referral }

    function calculateFees(uint256 amount, FeeType feeType) external view returns (uint256);
    function distributeFees(uint256 transactionId, uint256 totalFees) external;
    function setFeeRate(FeeType feeType, uint256 newRate) external;
    function collectPlatformFees() external;
    function processReferralReward(address referrer, uint256 amount) external;
}
