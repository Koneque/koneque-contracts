// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IAccount.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

contract SmartAccount is ISmartAccount, AccessControlEnumerable, ReentrancyGuard {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    
    address public guardian;
    bool public isInitialized;
    
    mapping(bytes32 => bool) public executedOperations;
    
    event Executed(address indexed target, uint256 value, bytes data);
    event BatchExecuted(uint256 operations);
    event OwnerAdded(address indexed newOwner);
    event OwnerRemoved(address indexed removedOwner);
    event GuardianSet(address indexed guardian);
    
    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, msg.sender), "Not an owner");
        _;
    }
    
    modifier onlyGuardian() {
        require(msg.sender == guardian, "Not the guardian");
        _;
    }
    
    function initialize(address owner) external {
        require(!isInitialized, "Already initialized");
        require(owner != address(0), "Invalid owner");
        
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(OWNER_ROLE, owner);
        isInitialized = true;
    }
    
    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) external override onlyOwner nonReentrant returns (bytes memory) {
        require(target != address(0), "Invalid target");
        
        (bool success, bytes memory result) = target.call{value: value}(data);
        require(success, "Execution failed");
        
        emit Executed(target, value, data);
        return result;
    }
    
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external override onlyOwner nonReentrant returns (bytes[] memory) {
        require(targets.length == values.length && targets.length == datas.length, "Array length mismatch");
        require(targets.length > 0, "Empty batch");
        
        bytes[] memory results = new bytes[](targets.length);
        
        for (uint256 i = 0; i < targets.length; i++) {
            require(targets[i] != address(0), "Invalid target");
            
            (bool success, bytes memory result) = targets[i].call{value: values[i]}(datas[i]);
            require(success, "Batch execution failed");
            results[i] = result;
        }
        
        emit BatchExecuted(targets.length);
        return results;
    }
    
    function validateUserOp(
        bytes32 userOpHash,
        uint256 maxCost
    ) external view override returns (uint256 validationData) {
        // Simplified validation - in production, implement proper signature validation
        // Return 0 for valid, 1 for invalid
        return 0;
    }
    
    function addOwner(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        require(!hasRole(OWNER_ROLE, newOwner), "Already an owner");
        
        _grantRole(OWNER_ROLE, newOwner);
        emit OwnerAdded(newOwner);
    }
    
    function removeOwner(address owner) external override {
        require(hasRole(OWNER_ROLE, owner), "Not an owner");
        require(getRoleMemberCount(OWNER_ROLE) > 1, "Cannot remove last owner");
        require(hasRole(OWNER_ROLE, msg.sender) || msg.sender == guardian, "Not authorized");
        
        _revokeRole(OWNER_ROLE, owner);
        emit OwnerRemoved(owner);
    }
    
    function setGuardian(address _guardian) external override onlyOwner {
        require(_guardian != address(0), "Invalid guardian");
        guardian = _guardian;
        emit GuardianSet(_guardian);
    }
    
    function socialRecovery(address newOwner, address oldOwner) external onlyGuardian {
        require(newOwner != address(0), "Invalid new owner");
        require(hasRole(OWNER_ROLE, oldOwner), "Old owner not found");
        
        _revokeRole(OWNER_ROLE, oldOwner);
        _grantRole(OWNER_ROLE, newOwner);
        
        emit OwnerRemoved(oldOwner);
        emit OwnerAdded(newOwner);
    }
    
    function getOwners() external view returns (address[] memory) {
        uint256 ownerCount = getRoleMemberCount(OWNER_ROLE);
        address[] memory owners = new address[](ownerCount);
        
        for (uint256 i = 0; i < ownerCount; i++) {
            owners[i] = getRoleMember(OWNER_ROLE, i);
        }
        
        return owners;
    }
    
    receive() external payable {}
    
    fallback() external payable {}
}
