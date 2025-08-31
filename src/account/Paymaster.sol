// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IAccount.sol";
import "../token/NativeToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Paymaster is IPaymaster, Ownable, ReentrancyGuard {
    NativeToken public immutable nativeToken;
    
    // Exchange rate: tokens per gas unit
    uint256 public tokenPerGas = 1e12; // 1 token = 1e12 gas units
    
    mapping(address => uint256) public deposits;
    mapping(address => bool) public whitelistedAccounts;
    
    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);
    event GasPaid(address indexed account, uint256 gasUsed, uint256 tokensCost);
    
    constructor(address _nativeToken) Ownable(msg.sender) {
        nativeToken = NativeToken(_nativeToken);
    }
    
    function validatePaymasterUserOp(
        bytes32 userOpHash,
        uint256 maxCost
    ) external view override returns (bytes memory context, uint256 validationData) {
        // Extract account from userOp (simplified)
        address account = msg.sender; // In real implementation, extract from userOp
        
        // Check if account has enough deposited tokens
        uint256 requiredTokens = (maxCost * tokenPerGas) / 1e18;
        
        if (deposits[account] >= requiredTokens || whitelistedAccounts[account]) {
            return (abi.encode(account, requiredTokens), 0); // Valid
        }
        
        return ("", 1); // Invalid
    }
    
    function postOp(
        uint8 mode,
        bytes calldata context,
        uint256 actualGasCost
    ) external override nonReentrant {
        (address account, uint256 maxTokens) = abi.decode(context, (address, uint256));
        
        uint256 actualTokenCost = (actualGasCost * tokenPerGas) / 1e18;
        
        if (!whitelistedAccounts[account]) {
            require(deposits[account] >= actualTokenCost, "Insufficient deposit");
            deposits[account] -= actualTokenCost;
        }
        
        emit GasPaid(account, actualGasCost, actualTokenCost);
    }
    
    function depositFor(address account, uint256 amount) external override {
        require(account != address(0), "Invalid account");
        require(amount > 0, "Invalid amount");
        
        require(nativeToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        deposits[account] += amount;
        
        emit Deposited(account, amount);
    }
    
    function withdrawTo(address recipient, uint256 amount) external override {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Invalid amount");
        require(deposits[msg.sender] >= amount, "Insufficient balance");
        
        deposits[msg.sender] -= amount;
        require(nativeToken.transfer(recipient, amount), "Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }
    
    function addToWhitelist(address account) external onlyOwner {
        whitelistedAccounts[account] = true;
    }
    
    function removeFromWhitelist(address account) external onlyOwner {
        whitelistedAccounts[account] = false;
    }
    
    function setTokenPerGas(uint256 _tokenPerGas) external onlyOwner {
        require(_tokenPerGas > 0, "Invalid rate");
        tokenPerGas = _tokenPerGas;
    }
    
    function getDeposit(address account) external view returns (uint256) {
        return deposits[account];
    }
    
    function withdrawOwnerFunds(uint256 amount) external onlyOwner {
        require(nativeToken.transfer(owner(), amount), "Transfer failed");
    }
}
