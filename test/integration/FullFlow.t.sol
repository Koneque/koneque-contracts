// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/token/NativeToken.sol";
import "../../src/account/AccountFactory.sol";
import "../../src/account/SmartAccount.sol";
import "../../src/account/Paymaster.sol";
import "../../src/marketplace/MarketplaceCore.sol";
import "../../src/marketplace/Escrow.sol";
import "../../src/marketplace/FeeManager.sol";
import "../../src/dispute/DisputeResolution.sol";
import "../../src/dispute/OracleRegistry.sol";
import "../../src/incentives/ReferralSystem.sol";

contract IntegrationTest is Test {
    // Core contracts
    NativeToken token;
    AccountFactory accountFactory;
    SmartAccount smartAccountImpl;
    Paymaster paymaster;
    MarketplaceCore marketplace;
    Escrow escrow;
    FeeManager feeManager;
    DisputeResolution disputeResolution;
    OracleRegistry oracleRegistry;
    ReferralSystem referralSystem;
    
    // Test accounts
    address buyer = makeAddr("buyer");
    address seller = makeAddr("seller");
    address referrer = makeAddr("referrer");
    address oracle1 = makeAddr("oracle1");
    address oracle2 = makeAddr("oracle2");
    address oracle3 = makeAddr("oracle3");
    
    function setUp() public {
        // Deploy token first
        token = new NativeToken();
        
        // Deploy account contracts
        smartAccountImpl = new SmartAccount();
        accountFactory = new AccountFactory(address(smartAccountImpl));
        paymaster = new Paymaster(address(token));
        
        // Deploy marketplace contracts
        marketplace = new MarketplaceCore(address(token));
        escrow = new Escrow(address(token));
        feeManager = new FeeManager(address(token), address(this)); // Add platform wallet address
        
        // Deploy dispute contracts
        oracleRegistry = new OracleRegistry(address(token));
        disputeResolution = new DisputeResolution(address(token));
        
        // Deploy incentive contracts
        referralSystem = new ReferralSystem(address(token));
        
        // Setup test data
        setupTestData();
    }
    
    function setupTestData() internal {
        // Mint tokens for participants
        token.mint(buyer, 100_000 * 10**18);
        token.mint(seller, 50_000 * 10**18);
        token.mint(referrer, 10_000 * 10**18);
        
        // Setup approvals for marketplace operations
        vm.prank(buyer);
        token.approve(address(marketplace), type(uint256).max);
        
        // Register oracles
        uint256 oracleStake = 10000 * 10**18;
        
        // Mint tokens for oracles
        token.mint(oracle1, oracleStake);
        token.mint(oracle2, oracleStake);
        token.mint(oracle3, oracleStake);
        
        vm.startPrank(oracle1);
        token.approve(address(oracleRegistry), oracleStake);
        oracleRegistry.registerOracle(oracleStake);
        vm.stopPrank();
        
        vm.startPrank(oracle2);
        token.approve(address(oracleRegistry), oracleStake);
        oracleRegistry.registerOracle(oracleStake);
        vm.stopPrank();
        
        vm.startPrank(oracle3);
        token.approve(address(oracleRegistry), oracleStake);
        oracleRegistry.registerOracle(oracleStake);
        vm.stopPrank();
    }
    
    function testCompleteMarketplaceFlow() public {
        // Mint tokens for fee manager to pay rewards
        token.mint(address(feeManager), 100_000 * 10**18);
        
        // Configure marketplace contracts
        marketplace.setEscrowContract(address(escrow));
        marketplace.setFeeManager(address(feeManager));
        
        escrow.setMarketplaceCore(address(marketplace));
        escrow.setDisputeResolution(address(disputeResolution));
        
        feeManager.setMarketplaceCore(address(marketplace));
        feeManager.setReferralSystem(address(referralSystem));
        
        referralSystem.setMarketplaceCore(address(marketplace));
        referralSystem.setFeeManager(address(feeManager));
        
        // 1. Register referral relationship
        vm.prank(buyer);
        referralSystem.registerReferral(referrer, buyer);
        
        // 2. List an item
        uint256 itemPrice = 10000 * 10**18;
        vm.prank(seller);
        uint256 itemId = marketplace.listItem(itemPrice, "ipfs://test-item", "Electronics");
        
        // 3. Buy the item
        vm.prank(buyer);
        uint256 transactionId = marketplace.buyItem(itemId);
        
        // Verify transaction created
        IMarketplaceCore.Transaction memory transaction = marketplace.getTransactionDetails(transactionId);
        assertEq(transaction.buyer, buyer);
        assertEq(transaction.seller, seller);
        assertEq(transaction.amount, itemPrice);
        
        // Verify escrow balance
        assertEq(escrow.getEscrowBalance(transactionId), itemPrice);
        assertEq(uint(escrow.getEscrowStatus(transactionId)), uint(IEscrow.EscrowStatus.Locked));
        
        // 4. Simulate marketplace recording first purchase (this would be done automatically)
        vm.prank(address(marketplace));
        referralSystem.recordFirstPurchase(buyer, itemPrice);
        
        // 5. Confirm delivery (happy path)
        uint256 sellerBalanceBefore = token.balanceOf(seller);
        
        vm.prank(buyer);
        marketplace.confirmDelivery(transactionId);
        
        // Verify seller received payment
        assertEq(token.balanceOf(seller), sellerBalanceBefore + itemPrice);
        
        // Verify escrow released
        assertEq(uint(escrow.getEscrowStatus(transactionId)), uint(IEscrow.EscrowStatus.Released));
        
        // 6. Claim referral reward
        uint256 referrerBalanceBefore = token.balanceOf(referrer);
        
        vm.prank(referrer);
        referralSystem.claimReferralReward(buyer);
        
        // Verify referrer received reward
        assertGt(token.balanceOf(referrer), referrerBalanceBefore);
        
        console.log("Complete marketplace flow test passed!");
    }
    
    function testBatchPurchaseFlow() public {
        marketplace.setEscrowContract(address(escrow));
        escrow.setMarketplaceCore(address(marketplace));
        
        // 1. List multiple items
        uint256[] memory itemIds = new uint256[](3);
        
        vm.startPrank(seller);
        itemIds[0] = marketplace.listItem(1000 * 10**18, "ipfs://item1", "Electronics");
        itemIds[1] = marketplace.listItem(2000 * 10**18, "ipfs://item2", "Books");
        itemIds[2] = marketplace.listItem(3000 * 10**18, "ipfs://item3", "Clothing");
        vm.stopPrank();
        
        // 2. Batch purchase (buyBatch only takes itemIds)
        uint256 totalCost = 6000 * 10**18;
        uint256 buyerBalanceBefore = token.balanceOf(buyer);
        
        vm.prank(buyer);
        uint256[] memory transactionIds = marketplace.buyBatch(itemIds);
        
        // Verify purchases
        assertEq(transactionIds.length, 3);
        assertEq(token.balanceOf(buyer), buyerBalanceBefore - totalCost);
        
        console.log("Batch purchase flow test passed!");
    }
    
    function testAccountAbstraction() public {
        // 1. Create smart account
        address smartAccount = accountFactory.createAccount(buyer, 0);
        assertTrue(accountFactory.isAccountDeployed(smartAccount));
        
        // 2. Deposit to paymaster
        uint256 depositAmount = 1000 * 10**18;
        token.mint(address(this), depositAmount); // Mint to test contract instead
        
        token.approve(address(paymaster), depositAmount);
        paymaster.depositFor(smartAccount, depositAmount);
        
        assertEq(paymaster.getDeposit(smartAccount), depositAmount);
        
        console.log("Account abstraction test passed!");
    }
    
    function testOracleStakingAndReputation() public {
        // Check initial oracle stats
        IOracleRegistry.Oracle memory oracle = oracleRegistry.getOracleStats(oracle1);
        assertEq(oracle.reputation, 50); // Initial reputation
        assertEq(oracle.totalVotes, 0);
        assertEq(oracle.correctVotes, 0);
        
        // Simulate oracle participation in disputes and reputation updates
        // This would normally happen through dispute resolution
        oracleRegistry.updateReputation(oracle1, true); // Correct decision
        oracleRegistry.updateReputation(oracle1, true); // Another correct decision
        oracleRegistry.updateReputation(oracle1, false); // Wrong decision
        
        IOracleRegistry.Oracle memory updatedOracle = oracleRegistry.getOracleStats(oracle1);
        assertEq(updatedOracle.totalVotes, 3);
        assertEq(updatedOracle.correctVotes, 2);
        assertGe(updatedOracle.reputation, oracle.reputation); // Reputation should increase or stay same
        
        console.log("Oracle staking and reputation test passed!");
    }
    
    function testEmergencyFunctions() public {
        marketplace.setEscrowContract(address(escrow));
        escrow.setMarketplaceCore(address(marketplace));
        
        // Setup a transaction
        uint256 itemPrice = 1000 * 10**18;
        vm.prank(seller);
        uint256 itemId = marketplace.listItem(itemPrice, "ipfs://emergency-item", "Electronics");
        
        vm.prank(buyer);
        uint256 transactionId = marketplace.buyItem(itemId);
        
        // Verify funds are locked
        assertEq(uint(escrow.getEscrowStatus(transactionId)), uint(IEscrow.EscrowStatus.Locked));
        
        // Fast forward time to allow emergency release (90 days)
        vm.warp(block.timestamp + 91 days);
        
        // Emergency refund by owner (to return funds to buyer)
        uint256 buyerBalanceBefore = token.balanceOf(buyer);
        escrow.emergencyRefund(transactionId);
        
        // Verify buyer received refund
        assertEq(token.balanceOf(buyer), buyerBalanceBefore + itemPrice);
        assertEq(uint(escrow.getEscrowStatus(transactionId)), uint(IEscrow.EscrowStatus.Refunded));
        
        console.log("Emergency functions test passed!");
    }
}
