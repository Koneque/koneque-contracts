// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract NativeToken is ERC20, Ownable, Pausable {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18; // 1 billion tokens
    
    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public stakingTimestamp;
    
    uint256 public stakingRewardRate = 100; // 1% per year (100 basis points)
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant SECONDS_PER_YEAR = 365 * 24 * 60 * 60;
    
    event Staked(address indexed user, uint256 amount, uint256 duration);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    
    constructor() ERC20("Koneque Token", "KNQ") Ownable(msg.sender) {
        // Mint initial supply to deployer
        _mint(msg.sender, 100_000_000 * 10**18); // 100M initial supply
    }
    
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        _mint(to, amount);
    }
    
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
    
    function stake(uint256 amount, uint256 duration) external whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(duration >= 30 days, "Minimum staking period is 30 days");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        // Transfer tokens to contract
        _transfer(msg.sender, address(this), amount);
        
        // Update staking data
        stakedBalances[msg.sender] += amount;
        stakingTimestamp[msg.sender] = block.timestamp;
        
        emit Staked(msg.sender, amount, duration);
    }
    
    function unstake() external {
        uint256 stakedAmount = stakedBalances[msg.sender];
        require(stakedAmount > 0, "No staked balance");
        require(block.timestamp >= stakingTimestamp[msg.sender] + 30 days, "Staking period not complete");
        
        // Calculate reward
        uint256 stakingDuration = block.timestamp - stakingTimestamp[msg.sender];
        uint256 reward = calculateStakingReward(stakedAmount, stakingDuration);
        
        // Reset staking data
        stakedBalances[msg.sender] = 0;
        stakingTimestamp[msg.sender] = 0;
        
        // Transfer staked amount back to user
        _transfer(address(this), msg.sender, stakedAmount);
        
        // Mint reward if any
        if (reward > 0 && totalSupply() + reward <= MAX_SUPPLY) {
            _mint(msg.sender, reward);
        }
        
        emit Unstaked(msg.sender, stakedAmount, reward);
    }
    
    function calculateStakingReward(uint256 amount, uint256 duration) public view returns (uint256) {
        return (amount * stakingRewardRate * duration) / (BASIS_POINTS * SECONDS_PER_YEAR);
    }
    
    function getStakingInfo(address user) external view returns (uint256 stakedAmount, uint256 stakingTime, uint256 pendingReward) {
        stakedAmount = stakedBalances[user];
        stakingTime = stakingTimestamp[user];
        
        if (stakedAmount > 0 && stakingTime > 0) {
            uint256 duration = block.timestamp - stakingTime;
            pendingReward = calculateStakingReward(stakedAmount, duration);
        }
    }
    
    function setStakingRewardRate(uint256 newRate) external onlyOwner {
        require(newRate <= 1000, "Rate cannot exceed 10%"); // Max 10% per year
        stakingRewardRate = newRate;
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    function _update(address from, address to, uint256 value) internal override whenNotPaused {
        super._update(from, to, value);
    }
}
