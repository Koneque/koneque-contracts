// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/token/NativeToken.sol";

contract NativeTokenTest is Test {
    NativeToken public token;
    address public owner;
    address public user1;
    address public user2;
    
    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        token = new NativeToken();
    }
    
    function testInitialState() public {
        assertEq(token.name(), "Koneque Token");
        assertEq(token.symbol(), "KNQ");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 100_000_000 * 10**18);
        assertEq(token.balanceOf(owner), 100_000_000 * 10**18);
    }
    
    function testMint() public {
        uint256 mintAmount = 1000 * 10**18;
        uint256 initialSupply = token.totalSupply();
        
        token.mint(user1, mintAmount);
        
        assertEq(token.balanceOf(user1), mintAmount);
        assertEq(token.totalSupply(), initialSupply + mintAmount);
    }
    
    function testMintExceedsMaxSupply() public {
        uint256 maxSupply = token.MAX_SUPPLY();
        uint256 currentSupply = token.totalSupply();
        uint256 excessAmount = maxSupply - currentSupply + 1;
        
        vm.expectRevert("Exceeds max supply");
        token.mint(user1, excessAmount);
    }
    
    function testBurn() public {
        uint256 burnAmount = 1000 * 10**18;
        uint256 initialBalance = token.balanceOf(owner);
        uint256 initialSupply = token.totalSupply();
        
        token.burn(burnAmount);
        
        assertEq(token.balanceOf(owner), initialBalance - burnAmount);
        assertEq(token.totalSupply(), initialSupply - burnAmount);
    }
    
    function testStaking() public {
        uint256 stakeAmount = 10000 * 10**18;
        
        // Transfer tokens to user1 first
        token.transfer(user1, stakeAmount);
        
        vm.startPrank(user1);
        token.stake(stakeAmount, 30 days);
        
        assertEq(token.stakedBalances(user1), stakeAmount);
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(address(token)), stakeAmount);
        vm.stopPrank();
    }
    
    function testStakingMinimumPeriod() public {
        uint256 stakeAmount = 1000 * 10**18;
        
        vm.expectRevert("Minimum staking period is 30 days");
        token.stake(stakeAmount, 29 days);
    }
    
    function testUnstakeBeforePeriod() public {
        uint256 stakeAmount = 1000 * 10**18;
        
        token.transfer(user1, stakeAmount);
        
        vm.startPrank(user1);
        token.stake(stakeAmount, 30 days);
        
        vm.expectRevert("Staking period not complete");
        token.unstake();
        vm.stopPrank();
    }
    
    function testSuccessfulUnstake() public {
        uint256 stakeAmount = 1000 * 10**18;
        
        token.transfer(user1, stakeAmount);
        
        vm.startPrank(user1);
        token.stake(stakeAmount, 30 days);
        
        // Fast forward 30 days
        vm.warp(block.timestamp + 30 days);
        
        token.unstake();
        
        assertEq(token.stakedBalances(user1), 0);
        assertGe(token.balanceOf(user1), stakeAmount); // Should have rewards
        vm.stopPrank();
    }
    
    function testOnlyOwnerCanMint() public {
        vm.prank(user1);
        vm.expectRevert();
        token.mint(user2, 1000 * 10**18);
    }
}
