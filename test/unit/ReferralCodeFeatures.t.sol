// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/incentives/ReferralSystem.sol";
import "../../src/token/NativeToken.sol";

contract ReferralCodeFeaturesTest is Test {
    ReferralSystem public referralSystem;
    NativeToken public token;
    
    address public owner = address(0x1);
    address public referrer = address(0x2);
    address public referred = address(0x3);
    
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18;
    uint256 public constant MIN_PURCHASE = 100 * 10**18;
    
    function setUp() public {
        vm.startPrank(owner);
        token = new NativeToken();
        referralSystem = new ReferralSystem(address(token));
        
        // Setup initial configuration
        referralSystem.setReferralRate(500); // 5%
        referralSystem.updateMinPurchaseAmount(MIN_PURCHASE);
        referralSystem.setMarketplaceCore(owner); // Set owner as marketplace for testing
        
        // Mint tokens for testing
        token.mint(owner, INITIAL_SUPPLY);
        vm.stopPrank();
        
        // Distribute tokens
        vm.prank(owner);
        token.transfer(referrer, 10_000 * 10**18);
    }
    
    function testCreateReferralCode() public {
        string memory code = "WELCOME2024";
        uint256 validityPeriod = 30 days;
        uint256 maxUsage = 100;
        
        vm.prank(referrer);
        referralSystem.createReferralCode(code, validityPeriod, maxUsage);
        
        // Verify code was created
        IReferralSystem.ReferralCode memory codeInfo = referralSystem.getReferralCodeInfo(code);
        assertEq(codeInfo.owner, referrer);
        assertTrue(codeInfo.isActive);
        assertEq(codeInfo.maxUsage, maxUsage);
        assertTrue(codeInfo.expiresAt > block.timestamp);
        assertEq(codeInfo.usageCount, 0);
    }
    
    function testReferralCodeExpiration() public {
        string memory code = "SHORTCODE";
        uint256 validityPeriod = 1 days;
        uint256 maxUsage = 10;
        
        vm.prank(referrer);
        referralSystem.createReferralCode(code, validityPeriod, maxUsage);
        
        // Code should be valid initially
        assertTrue(referralSystem.isReferralCodeValid(code));
        
        // Fast forward past expiration
        vm.warp(block.timestamp + 2 days);
        
        // Code should now be invalid
        assertFalse(referralSystem.isReferralCodeValid(code));
    }
    
    function testRegisterWithReferralCode() public {
        string memory code = "FRIEND2024";
        uint256 validityPeriod = 30 days;
        uint256 maxUsage = 50;
        
        // Create referral code
        vm.prank(referrer);
        referralSystem.createReferralCode(code, validityPeriod, maxUsage);
        
        // Register referred user with code
        vm.prank(referred);
        referralSystem.registerReferralWithCode(code, referred);
        
        // Verify registration
        address registeredReferrer = referralSystem.getReferrerOf(referred);
        assertEq(registeredReferrer, referrer);
        
        // Verify code usage count increased
        IReferralSystem.ReferralCode memory codeInfo = referralSystem.getReferralCodeInfo(code);
        assertEq(codeInfo.usageCount, 1);
    }
    
    function testCannotUseOwnReferralCode() public {
        string memory code = "MYCODE";
        uint256 validityPeriod = 30 days;
        uint256 maxUsage = 10;
        
        // Create referral code
        vm.prank(referrer);
        referralSystem.createReferralCode(code, validityPeriod, maxUsage);
        
        // Try to use own code - should fail
        vm.prank(referrer);
        vm.expectRevert("Cannot use own code");
        referralSystem.registerReferralWithCode(code, referrer);
    }
    
    function testCannotRegisterWithExpiredCode() public {
        string memory code = "EXPIRED";
        uint256 validityPeriod = 1 hours;
        uint256 maxUsage = 10;
        
        // Create referral code
        vm.prank(referrer);
        referralSystem.createReferralCode(code, validityPeriod, maxUsage);
        
        // Fast forward past expiration
        vm.warp(block.timestamp + 2 hours);
        
        // Try to register with expired code - should fail
        vm.prank(referred);
        vm.expectRevert("Invalid or expired code");
        referralSystem.registerReferralWithCode(code, referred);
    }
    
    function testReferralExpirationAfterRegistration() public {
        string memory code = "EXPIRETEST";
        uint256 validityPeriod = 30 days;
        uint256 maxUsage = 10;
        
        // Create code and register
        vm.prank(referrer);
        referralSystem.createReferralCode(code, validityPeriod, maxUsage);
        
        vm.prank(referred);
        referralSystem.registerReferralWithCode(code, referred);
        
        // Simulate first purchase to make referral eligible for reward
        vm.prank(owner);
        referralSystem.recordFirstPurchase(referred, MIN_PURCHASE);
        
        // Should be eligible for reward after purchase
        assertTrue(referralSystem.isEligibleForReward(referred));
        
        // Fast forward past referral expiration (90 days default)
        vm.warp(block.timestamp + 91 days);
        
        // Should no longer be eligible for reward
        assertFalse(referralSystem.isEligibleForReward(referred));
        
        // Should have zero pending reward
        assertEq(referralSystem.getPendingReward(referred), 0);
    }
    
    function testCodeUsageLimitReached() public {
        string memory code = "LIMITED";
        uint256 validityPeriod = 30 days;
        uint256 maxUsage = 2;
        
        // Create referral code with limit of 2
        vm.prank(referrer);
        referralSystem.createReferralCode(code, validityPeriod, maxUsage);
        
        // Use code twice successfully
        address user1 = address(0x4);
        address user2 = address(0x5);
        address user3 = address(0x6);
        
        vm.prank(user1);
        referralSystem.registerReferralWithCode(code, user1);
        
        vm.prank(user2);
        referralSystem.registerReferralWithCode(code, user2);
        
        // Third usage should fail
        vm.prank(user3);
        vm.expectRevert("Invalid or expired code");
        referralSystem.registerReferralWithCode(code, user3);
        
        // Verify usage count
        IReferralSystem.ReferralCode memory codeInfo = referralSystem.getReferralCodeInfo(code);
        assertEq(codeInfo.usageCount, 2);
    }
    
    function testCannotCreateDuplicateCode() public {
        string memory code = "UNIQUE";
        uint256 validityPeriod = 30 days;
        uint256 maxUsage = 10;
        
        // Create first code
        vm.prank(referrer);
        referralSystem.createReferralCode(code, validityPeriod, maxUsage);
        
        // Try to create duplicate - should fail
        vm.prank(referrer);
        vm.expectRevert("Code already exists");
        referralSystem.createReferralCode(code, validityPeriod, maxUsage);
    }
}
