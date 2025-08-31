// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/account/SmartAccount.sol";
import "../../src/account/SmartAccountFactory.sol";

contract SmartAccountTest is Test {
    SmartAccount public smartAccount;
    SmartAccountFactory public factory;
    
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public guardian = address(0x4);
    
    function setUp() public {
        factory = new SmartAccountFactory();
    }
    
    function testCreateSmartAccount() public {
        bytes32 salt = keccak256("test");
        
        vm.prank(user1);
        address smartAccountAddr = factory.createSmartAccount(owner, salt);
        
        assertTrue(smartAccountAddr != address(0));
        assertTrue(factory.isValidSmartAccount(smartAccountAddr));
        
        SmartAccount createdAccount = SmartAccount(payable(smartAccountAddr));
        assertTrue(createdAccount.hasRole(createdAccount.OWNER_ROLE(), owner));
        assertTrue(createdAccount.isInitialized());
    }
    
    function testCreateSmartAccountAutoSalt() public {
        vm.prank(user1);
        address smartAccountAddr = factory.createSmartAccountAutoSalt(owner);
        
        assertTrue(smartAccountAddr != address(0));
        assertTrue(factory.isValidSmartAccount(smartAccountAddr));
        
        address[] memory userAccounts = factory.getUserAccounts(owner);
        assertEq(userAccounts.length, 1);
        assertEq(userAccounts[0], smartAccountAddr);
    }
    
    function testPredictSmartAccountAddress() public {
        bytes32 salt = keccak256("predict");
        
        address predictedAddr = factory.getSmartAccountAddress(salt);
        
        vm.prank(user1);
        address actualAddr = factory.createSmartAccount(owner, salt);
        
        assertEq(predictedAddr, actualAddr);
    }
    
    function testMultipleAccountsPerUser() public {
        vm.startPrank(user1);
        
        address account1 = factory.createSmartAccountAutoSalt(owner);
        address account2 = factory.createSmartAccountAutoSalt(owner);
        address account3 = factory.createSmartAccountAutoSalt(owner);
        
        vm.stopPrank();
        
        address[] memory userAccounts = factory.getUserAccounts(owner);
        assertEq(userAccounts.length, 3);
        assertEq(userAccounts[0], account1);
        assertEq(userAccounts[1], account2);
        assertEq(userAccounts[2], account3);
        
        assertEq(factory.getUserAccountCount(owner), 3);
    }
    
    function testCannotCreateWithZeroAddress() public {
        bytes32 salt = keccak256("zero");
        
        vm.expectRevert("Invalid owner address");
        factory.createSmartAccount(address(0), salt);
    }
    
    function testSmartAccountExecution() public {
        vm.prank(user1);
        address smartAccountAddr = factory.createSmartAccountAutoSalt(owner);
        SmartAccount account = SmartAccount(payable(smartAccountAddr));
        
        // Mock contract to call
        MockTarget target = new MockTarget();
        
        vm.prank(owner);
        bytes memory result = account.execute(
            address(target),
            0,
            abi.encodeWithSignature("setValue(uint256)", 42)
        );
        
        assertEq(target.value(), 42);
    }
    
    function testOnlyOwnerCanExecute() public {
        vm.prank(user1);
        address smartAccountAddr = factory.createSmartAccountAutoSalt(owner);
        SmartAccount account = SmartAccount(payable(smartAccountAddr));
        
        MockTarget target = new MockTarget();
        
        vm.prank(user2); // Not the owner
        vm.expectRevert("Not an owner");
        account.execute(
            address(target),
            0,
            abi.encodeWithSignature("setValue(uint256)", 42)
        );
    }
    
    function testAddAndRemoveOwner() public {
        vm.prank(user1);
        address smartAccountAddr = factory.createSmartAccountAutoSalt(owner);
        SmartAccount account = SmartAccount(payable(smartAccountAddr));
        
        // Add new owner
        vm.prank(owner);
        account.addOwner(user2);
        
        assertTrue(account.hasRole(account.OWNER_ROLE(), user2));
        
        // New owner can execute
        MockTarget target = new MockTarget();
        vm.prank(user2);
        account.execute(
            address(target),
            0,
            abi.encodeWithSignature("setValue(uint256)", 100)
        );
        
        assertEq(target.value(), 100);
        
        // Remove owner
        vm.prank(owner);
        account.removeOwner(user2);
        
        assertFalse(account.hasRole(account.OWNER_ROLE(), user2));
    }
    
    function testSetGuardian() public {
        vm.prank(user1);
        address smartAccountAddr = factory.createSmartAccountAutoSalt(owner);
        SmartAccount account = SmartAccount(payable(smartAccountAddr));
        
        vm.prank(owner);
        account.setGuardian(guardian);
        
        assertEq(account.guardian(), guardian);
    }
    
    function testBatchExecution() public {
        vm.prank(user1);
        address smartAccountAddr = factory.createSmartAccountAutoSalt(owner);
        SmartAccount account = SmartAccount(payable(smartAccountAddr));
        
        MockTarget target1 = new MockTarget();
        MockTarget target2 = new MockTarget();
        
        address[] memory targets = new address[](2);
        uint256[] memory values = new uint256[](2);
        bytes[] memory datas = new bytes[](2);
        
        targets[0] = address(target1);
        values[0] = 0;
        datas[0] = abi.encodeWithSignature("setValue(uint256)", 123);
        
        targets[1] = address(target2);
        values[1] = 0;
        datas[1] = abi.encodeWithSignature("setValue(uint256)", 456);
        
        vm.prank(owner);
        account.executeBatch(targets, values, datas);
        
        assertEq(target1.value(), 123);
        assertEq(target2.value(), 456);
    }
}

// Mock contract for testing
contract MockTarget {
    uint256 public value;
    
    function setValue(uint256 _value) external {
        value = _value;
    }
}
