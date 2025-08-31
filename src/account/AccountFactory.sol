// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IAccount.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AccountFactory is IAccountFactory, Ownable {
    address public immutable smartAccountImplementation;
    
    mapping(address => bool) public deployedAccounts;
    
    event AccountCreated(address indexed owner, address indexed account, uint256 salt);
    
    constructor(address _implementation) Ownable(msg.sender) {
        smartAccountImplementation = _implementation;
    }
    
    function createAccount(address owner, uint256 salt) external override returns (address) {
        address account = getAccountAddress(owner, salt);
        
        if (deployedAccounts[account]) {
            return account;
        }
        
        bytes memory initCode = abi.encodePacked(
            type(SmartAccountProxy).creationCode,
            abi.encode(smartAccountImplementation, owner)
        );
        
        address deployedAccount = Create2.deploy(0, bytes32(salt), initCode);
        deployedAccounts[deployedAccount] = true;
        
        emit AccountCreated(owner, deployedAccount, salt);
        return deployedAccount;
    }
    
    function getAccountAddress(address owner, uint256 salt) public view override returns (address) {
        bytes memory initCode = abi.encodePacked(
            type(SmartAccountProxy).creationCode,
            abi.encode(smartAccountImplementation, owner)
        );
        
        return Create2.computeAddress(bytes32(salt), keccak256(initCode));
    }
    
    function isAccountDeployed(address account) external view override returns (bool) {
        return deployedAccounts[account];
    }
}

contract SmartAccountProxy {
    address public immutable implementation;
    
    constructor(address _implementation, address _owner) {
        implementation = _implementation;
        // Initialize the implementation with owner
        (bool success,) = _implementation.delegatecall(
            abi.encodeWithSignature("initialize(address)", _owner)
        );
        require(success, "Initialization failed");
    }
    
    fallback() external payable {
        address impl = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    receive() external payable {}
}
