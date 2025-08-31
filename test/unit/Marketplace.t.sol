// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/marketplace/MarketplaceCore.sol";
import "../../src/marketplace/Escrow.sol";
import "../../src/marketplace/FeeManager.sol";
import "../../src/token/NativeToken.sol";

contract MarketplaceTest is Test {
    MarketplaceCore public marketplace;
    Escrow public escrow;
    FeeManager public feeManager;
    NativeToken public token;
    
    address public owner;
    address public seller;
    address public buyer;
    address public platformWallet;
    
    function setUp() public {
        owner = address(this);
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");
        platformWallet = makeAddr("platform");
        
        // Deploy contracts
        token = new NativeToken();
        marketplace = new MarketplaceCore(address(token));
        escrow = new Escrow(address(token));
        feeManager = new FeeManager(address(token), platformWallet);
        
        // Configure relationships
        marketplace.setEscrowContract(address(escrow));
        marketplace.setFeeManager(address(feeManager));
        escrow.setMarketplaceCore(address(marketplace));
        feeManager.setMarketplaceCore(address(marketplace));
        
        // Mint tokens for testing
        token.mint(seller, 100000 * 10**18);
        token.mint(buyer, 100000 * 10**18);
        
        // Approve escrow to spend tokens
        vm.prank(buyer);
        token.approve(address(marketplace), type(uint256).max);
    }
    
    function testListItem() public {
        uint256 price = 1000 * 10**18;
        string memory metadataURI = "ipfs://test-metadata";
        string memory category = "Electronics";
        
        vm.prank(seller);
        uint256 itemId = marketplace.listItem(price, metadataURI, category);
        
        IMarketplaceCore.Item memory item = marketplace.getItemDetails(itemId);
        assertEq(item.id, itemId);
        assertEq(item.seller, seller);
        assertEq(item.price, price);
        assertEq(item.metadataURI, metadataURI);
        assertEq(item.category, category);
        assertTrue(item.isActive);
        assertEq(item.createdAt, block.timestamp);
    }
    
    function testBuyItem() public {
        // First list an item
        uint256 price = 1000 * 10**18;
        vm.prank(seller);
        uint256 itemId = marketplace.listItem(price, "ipfs://test", "Electronics");
        
        // Buyer purchases item
        vm.prank(buyer);
        uint256 transactionId = marketplace.buyItem(itemId);
        
        // Check transaction details
        IMarketplaceCore.Transaction memory transaction = marketplace.getTransactionDetails(transactionId);
        assertEq(transaction.itemId, itemId);
        assertEq(transaction.buyer, buyer);
        assertEq(transaction.seller, seller);
        assertEq(transaction.amount, price);
        assertFalse(transaction.isConfirmed);
        assertFalse(transaction.isDisputed);
        
        // Check item is no longer active
        IMarketplaceCore.Item memory item = marketplace.getItemDetails(itemId);
        assertFalse(item.isActive);
        
        // Check escrow balance
        assertEq(escrow.getEscrowBalance(transactionId), price);
        assertEq(uint(escrow.getEscrowStatus(transactionId)), uint(IEscrow.EscrowStatus.Locked));
    }
    
    function testConfirmDelivery() public {
        // List and buy item
        uint256 price = 1000 * 10**18;
        vm.prank(seller);
        uint256 itemId = marketplace.listItem(price, "ipfs://test", "Electronics");
        
        vm.prank(buyer);
        uint256 transactionId = marketplace.buyItem(itemId);
        
        uint256 sellerBalanceBefore = token.balanceOf(seller);
        
        // Confirm delivery
        vm.prank(buyer);
        marketplace.confirmDelivery(transactionId);
        
        // Check transaction is confirmed
        IMarketplaceCore.Transaction memory transaction = marketplace.getTransactionDetails(transactionId);
        assertTrue(transaction.isConfirmed);
        
        // Check seller received payment
        assertEq(token.balanceOf(seller), sellerBalanceBefore + price);
        
        // Check escrow is released
        assertEq(uint(escrow.getEscrowStatus(transactionId)), uint(IEscrow.EscrowStatus.Released));
    }
    
    function testBuyBatch() public {
        // List multiple items
        uint256[] memory itemIds = new uint256[](3);
        uint256[] memory prices = new uint256[](3);
        
        for (uint256 i = 0; i < 3; i++) {
            prices[i] = (i + 1) * 1000 * 10**18;
            vm.prank(seller);
            itemIds[i] = marketplace.listItem(prices[i], "ipfs://test", "Electronics");
        }
        
        uint256 totalPrice = prices[0] + prices[1] + prices[2];
        
        // Buy batch
        vm.prank(buyer);
        uint256[] memory transactionIds = marketplace.buyBatch(itemIds);
        
        assertEq(transactionIds.length, 3);
        
        // Check all transactions are created
        for (uint256 i = 0; i < 3; i++) {
            IMarketplaceCore.Transaction memory transaction = marketplace.getTransactionDetails(transactionIds[i]);
            assertEq(transaction.itemId, itemIds[i]);
            assertEq(transaction.buyer, buyer);
            assertEq(transaction.seller, seller);
            assertEq(transaction.amount, prices[i]);
        }
        
        // Check total escrow balance
        uint256 totalEscrowed = 0;
        for (uint256 i = 0; i < 3; i++) {
            totalEscrowed += escrow.getEscrowBalance(transactionIds[i]);
        }
        assertEq(totalEscrowed, totalPrice);
    }
    
    function testCannotBuyOwnItem() public {
        vm.startPrank(seller);
        uint256 itemId = marketplace.listItem(1000 * 10**18, "ipfs://test", "Electronics");
        
        vm.expectRevert("Cannot buy own item");
        marketplace.buyItem(itemId);
        vm.stopPrank();
    }
    
    function testCannotBuyInactiveItem() public {
        vm.prank(seller);
        uint256 itemId = marketplace.listItem(1000 * 10**18, "ipfs://test", "Electronics");
        
        // Cancel the listing
        vm.prank(seller);
        marketplace.cancelListing(itemId);
        
        // Try to buy cancelled item
        vm.prank(buyer);
        vm.expectRevert("Item not available");
        marketplace.buyItem(itemId);
    }
    
    function testGetActiveListings() public {
        // List several items
        vm.startPrank(seller);
        marketplace.listItem(1000 * 10**18, "ipfs://test1", "Electronics");
        marketplace.listItem(2000 * 10**18, "ipfs://test2", "Books");
        uint256 itemId3 = marketplace.listItem(3000 * 10**18, "ipfs://test3", "Clothing");
        vm.stopPrank();
        
        // Cancel one item
        vm.prank(seller);
        marketplace.cancelListing(itemId3);
        
        // Get active listings
        IMarketplaceCore.Item[] memory activeItems = marketplace.getActiveListings();
        assertEq(activeItems.length, 2);
        assertEq(activeItems[0].price, 1000 * 10**18);
        assertEq(activeItems[1].price, 2000 * 10**18);
    }
}
