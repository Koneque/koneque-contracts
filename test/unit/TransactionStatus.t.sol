// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/marketplace/MarketplaceCore.sol";
import "../../src/marketplace/Escrow.sol";
import "../../src/marketplace/FeeManager.sol";
import "../../src/token/NativeToken.sol";
import "../../src/interfaces/IMarketplace.sol";

contract TransactionStatusTest is Test {
    MarketplaceCore public marketplace;
    Escrow public escrow;
    FeeManager public feeManager;
    NativeToken public token;
    
    address public owner = address(0x1);
    address public seller = address(0x2);
    address public buyer = address(0x3);
    address public platformWallet = address(0x4);
    
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18;
    uint256 public constant ITEM_PRICE = 1000 * 10**18;
    
    function setUp() public {
        vm.startPrank(owner);
        token = new NativeToken();
        marketplace = new MarketplaceCore(address(token));
        escrow = new Escrow(address(token));
        feeManager = new FeeManager(address(token), platformWallet);
        
        // Mint tokens for testing
        token.mint(owner, INITIAL_SUPPLY);
        
        // Configure contracts
        marketplace.setEscrowContract(address(escrow));
        marketplace.setFeeManager(address(feeManager));
        escrow.setMarketplaceCore(address(marketplace));
        feeManager.setMarketplaceCore(address(marketplace));
        
        vm.stopPrank();
        
        // Distribute tokens
        vm.prank(owner);
        token.transfer(buyer, 10_000 * 10**18);
        
        // Approve tokens for marketplace
        vm.prank(buyer);
        token.approve(address(marketplace), type(uint256).max);
        
        // Approve escrow to receive tokens
        vm.prank(owner);
        token.approve(address(escrow), type(uint256).max);
    }
    
    function testTransactionStatusProgression() public {
        // 1. List item
        vm.prank(seller);
        uint256 itemId = marketplace.listItem(
            ITEM_PRICE,
            "Test Item",
            "Electronics"
        );
        
        // 2. Buy item - should start with PAYMENT_COMPLETED
        vm.prank(buyer);
        uint256 transactionId = marketplace.buyItem(itemId);
        
        IMarketplaceCore.Transaction memory transaction = marketplace.getTransactionDetails(transactionId);
        assertEq(uint(transaction.status), uint(IMarketplaceCore.TransactionStatus.PAYMENT_COMPLETED));
        
        // 3. Confirm delivery - should change to PRODUCT_DELIVERED
        vm.prank(buyer);
        marketplace.confirmDelivery(transactionId);
        
        transaction = marketplace.getTransactionDetails(transactionId);
        assertEq(uint(transaction.status), uint(IMarketplaceCore.TransactionStatus.PRODUCT_DELIVERED));
        
        // 4. Finalize transaction - should change to FINALIZED
        vm.prank(buyer);
        marketplace.finalizeTransaction(transactionId);
        
        transaction = marketplace.getTransactionDetails(transactionId);
        assertEq(uint(transaction.status), uint(IMarketplaceCore.TransactionStatus.FINALIZED));
    }
    
    function testDisputeFlow() public {
        // Setup transaction
        vm.prank(seller);
        uint256 itemId = marketplace.listItem(ITEM_PRICE, "Test Item", "Electronics");
        
        vm.prank(buyer);
        uint256 transactionId = marketplace.buyItem(itemId);
        
        // Buyer initiates dispute after payment
        vm.prank(buyer);
        marketplace.initiateDispute(transactionId);
        
        IMarketplaceCore.Transaction memory transaction = marketplace.getTransactionDetails(transactionId);
        assertEq(uint(transaction.status), uint(IMarketplaceCore.TransactionStatus.IN_DISPUTE));
        assertTrue(transaction.isDisputed);
    }
    
    function testSellerCanInitiateDispute() public {
        // Setup transaction and confirm delivery
        vm.prank(seller);
        uint256 itemId = marketplace.listItem(ITEM_PRICE, "Test Item", "Electronics");
        
        vm.prank(buyer);
        uint256 transactionId = marketplace.buyItem(itemId);
        
        vm.prank(buyer);
        marketplace.confirmDelivery(transactionId);
        
        // Seller initiates dispute after delivery confirmation
        vm.prank(seller);
        marketplace.initiateDispute(transactionId);
        
        IMarketplaceCore.Transaction memory transaction = marketplace.getTransactionDetails(transactionId);
        assertEq(uint(transaction.status), uint(IMarketplaceCore.TransactionStatus.IN_DISPUTE));
        assertTrue(transaction.isDisputed);
    }
    
    function testCannotDisputeAfterFinalization() public {
        // Complete full transaction flow
        vm.prank(seller);
        uint256 itemId = marketplace.listItem(ITEM_PRICE, "Test Item", "Electronics");
        
        vm.prank(buyer);
        uint256 transactionId = marketplace.buyItem(itemId);
        
        vm.prank(buyer);
        marketplace.confirmDelivery(transactionId);
        
        vm.prank(buyer);
        marketplace.finalizeTransaction(transactionId);
        
        // Try to dispute finalized transaction - should fail
        vm.prank(buyer);
        vm.expectRevert("Invalid status for dispute");
        marketplace.initiateDispute(transactionId);
    }
    
    function testCannotFinalizeBeforeDelivery() public {
        vm.prank(seller);
        uint256 itemId = marketplace.listItem(ITEM_PRICE, "Test Item", "Electronics");
        
        vm.prank(buyer);
        uint256 transactionId = marketplace.buyItem(itemId);
        
        // Try to finalize without confirming delivery first
        vm.prank(buyer);
        vm.expectRevert("Product not delivered");
        marketplace.finalizeTransaction(transactionId);
    }
    
    function testCannotConfirmDeliveryTwice() public {
        vm.prank(seller);
        uint256 itemId = marketplace.listItem(ITEM_PRICE, "Test Item", "Electronics");
        
        vm.prank(buyer);
        uint256 transactionId = marketplace.buyItem(itemId);
        
        vm.prank(buyer);
        marketplace.confirmDelivery(transactionId);
        
        // Try to confirm delivery again
        vm.prank(buyer);
        vm.expectRevert("Invalid status");
        marketplace.confirmDelivery(transactionId);
    }
    
    function testRefundTransaction() public {
        vm.prank(seller);
        uint256 itemId = marketplace.listItem(ITEM_PRICE, "Test Item", "Electronics");
        
        vm.prank(buyer);
        uint256 transactionId = marketplace.buyItem(itemId);
        
        // Initiate dispute
        vm.prank(buyer);
        marketplace.initiateDispute(transactionId);
        
        // Only escrow can refund
        vm.prank(address(escrow));
        marketplace.refundTransaction(transactionId);
        
        IMarketplaceCore.Transaction memory transaction = marketplace.getTransactionDetails(transactionId);
        assertEq(uint(transaction.status), uint(IMarketplaceCore.TransactionStatus.REFUNDED));
    }
    
    function testGetTransactionsByStatus() public {
        // Create multiple transactions with different statuses
        vm.prank(seller);
        uint256 itemId1 = marketplace.listItem(ITEM_PRICE, "Item 1", "Electronics");
        vm.prank(seller);
        uint256 itemId2 = marketplace.listItem(ITEM_PRICE, "Item 2", "Electronics");
        vm.prank(seller);
        uint256 itemId3 = marketplace.listItem(ITEM_PRICE, "Item 3", "Electronics");
        
        vm.prank(buyer);
        uint256 transactionId1 = marketplace.buyItem(itemId1);
        vm.prank(buyer);
        uint256 transactionId2 = marketplace.buyItem(itemId2);
        vm.prank(buyer);
        uint256 transactionId3 = marketplace.buyItem(itemId3);
        
        // All should be in PAYMENT_COMPLETED status
        IMarketplaceCore.Transaction[] memory paymentCompleted = marketplace.getTransactionsByStatus(
            IMarketplaceCore.TransactionStatus.PAYMENT_COMPLETED
        );
        assertEq(paymentCompleted.length, 3);
        
        // Confirm delivery on one
        vm.prank(buyer);
        marketplace.confirmDelivery(transactionId1);
        
        // Should have 2 in PAYMENT_COMPLETED and 1 in PRODUCT_DELIVERED
        paymentCompleted = marketplace.getTransactionsByStatus(
            IMarketplaceCore.TransactionStatus.PAYMENT_COMPLETED
        );
        assertEq(paymentCompleted.length, 2);
        
        IMarketplaceCore.Transaction[] memory productDelivered = marketplace.getTransactionsByStatus(
            IMarketplaceCore.TransactionStatus.PRODUCT_DELIVERED
        );
        assertEq(productDelivered.length, 1);
        assertEq(productDelivered[0].id, transactionId1);
    }
    
    function testUpdateTransactionStatusOnlyEscrow() public {
        vm.prank(seller);
        uint256 itemId = marketplace.listItem(ITEM_PRICE, "Test Item", "Electronics");
        
        vm.prank(buyer);
        uint256 transactionId = marketplace.buyItem(itemId);
        
        // Only escrow should be able to update status
        vm.prank(address(escrow));
        marketplace.updateTransactionStatus(transactionId, IMarketplaceCore.TransactionStatus.REFUNDED);
        
        IMarketplaceCore.Transaction memory transaction = marketplace.getTransactionDetails(transactionId);
        assertEq(uint(transaction.status), uint(IMarketplaceCore.TransactionStatus.REFUNDED));
        
        // Non-escrow should fail
        vm.prank(buyer);
        vm.expectRevert("Only escrow can call");
        marketplace.updateTransactionStatus(transactionId, IMarketplaceCore.TransactionStatus.FINALIZED);
    }
}
