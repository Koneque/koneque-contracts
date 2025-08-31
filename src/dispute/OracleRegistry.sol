// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IDispute.sol";
import "../token/NativeToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract OracleRegistry is IOracleRegistry, Ownable, ReentrancyGuard {
    NativeToken public immutable nativeToken;
    
    uint256 public constant MIN_STAKE = 10000 * 10**18; // 10,000 tokens minimum stake
    uint256 public constant MAX_REPUTATION = 100;
    uint256 public constant INITIAL_REPUTATION = 50;
    
    mapping(address => Oracle) public oracles;
    address[] public activeOracles;
    mapping(address => uint256) public oracleIndex; // Index in activeOracles array
    
    uint256 public totalStaked;
    
    event OracleRegistered(address indexed oracle, uint256 stake);
    event OracleDeactivated(address indexed oracle);
    event ReputationUpdated(address indexed oracle, uint256 oldReputation, uint256 newReputation);
    event OracleRewarded(address indexed oracle, uint256 amount);
    event OracleSlashed(address indexed oracle, uint256 amount);
    event StakeIncreased(address indexed oracle, uint256 amount);
    event StakeWithdrawn(address indexed oracle, uint256 amount);
    
    modifier onlyActiveOracle() {
        require(oracles[msg.sender].isActive, "Not an active oracle");
        _;
    }
    
    modifier onlyDisputeResolution() {
        // In production, this would be set to the dispute resolution contract
        _;
    }
    
    constructor(address _nativeToken) Ownable(msg.sender) {
        nativeToken = NativeToken(_nativeToken);
    }
    
    function registerOracle(uint256 stake) external override nonReentrant {
        require(stake >= MIN_STAKE, "Insufficient stake");
        require(!oracles[msg.sender].isActive, "Already registered");
        require(nativeToken.balanceOf(msg.sender) >= stake, "Insufficient balance");
        
        require(nativeToken.transferFrom(msg.sender, address(this), stake), "Transfer failed");
        
        oracles[msg.sender] = Oracle({
            oracleAddress: msg.sender,
            stake: stake,
            reputation: INITIAL_REPUTATION,
            totalVotes: 0,
            correctVotes: 0,
            isActive: true,
            registeredAt: block.timestamp
        });
        
        activeOracles.push(msg.sender);
        oracleIndex[msg.sender] = activeOracles.length - 1;
        totalStaked += stake;
        
        emit OracleRegistered(msg.sender, stake);
    }
    
    function increaseStake(uint256 amount) external onlyActiveOracle nonReentrant {
        require(amount > 0, "Invalid amount");
        require(nativeToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        oracles[msg.sender].stake += amount;
        totalStaked += amount;
        
        emit StakeIncreased(msg.sender, amount);
    }
    
    function withdrawStake(uint256 amount) external onlyActiveOracle nonReentrant {
        Oracle storage oracle = oracles[msg.sender];
        require(amount > 0, "Invalid amount");
        require(oracle.stake >= amount + MIN_STAKE, "Cannot withdraw below minimum");
        
        oracle.stake -= amount;
        totalStaked -= amount;
        
        require(nativeToken.transfer(msg.sender, amount), "Transfer failed");
        
        emit StakeWithdrawn(msg.sender, amount);
    }
    
    function deactivateOracle() external onlyActiveOracle {
        Oracle storage oracle = oracles[msg.sender];
        oracle.isActive = false;
        
        // Remove from active array
        uint256 index = oracleIndex[msg.sender];
        uint256 lastIndex = activeOracles.length - 1;
        
        if (index != lastIndex) {
            address lastOracle = activeOracles[lastIndex];
            activeOracles[index] = lastOracle;
            oracleIndex[lastOracle] = index;
        }
        
        activeOracles.pop();
        delete oracleIndex[msg.sender];
        
        // Return stake
        uint256 stakeToReturn = oracle.stake;
        oracle.stake = 0;
        totalStaked -= stakeToReturn;
        
        require(nativeToken.transfer(msg.sender, stakeToReturn), "Transfer failed");
        
        emit OracleDeactivated(msg.sender);
    }
    
    function updateReputation(address oracle, bool correctDecision) external override onlyDisputeResolution {
        require(oracles[oracle].isActive, "Oracle not active");
        
        Oracle storage oracleData = oracles[oracle];
        uint256 oldReputation = oracleData.reputation;
        
        oracleData.totalVotes++;
        
        if (correctDecision) {
            oracleData.correctVotes++;
            // Increase reputation (max 100)
            if (oracleData.reputation < MAX_REPUTATION) {
                oracleData.reputation = oracleData.reputation + 1;
            }
        } else {
            // Decrease reputation (min 1)
            if (oracleData.reputation > 1) {
                oracleData.reputation = oracleData.reputation - 2;
            }
        }
        
        emit ReputationUpdated(oracle, oldReputation, oracleData.reputation);
    }
    
    function selectOracles(uint256 transactionId, uint256 count) external override view returns (address[] memory) {
        require(count <= activeOracles.length, "Not enough oracles");
        require(count > 0, "Invalid count");
        
        address[] memory selected = new address[](count);
        uint256[] memory weights = new uint256[](activeOracles.length);
        uint256 totalWeight = 0;
        
        // Calculate weights based on reputation and stake
        for (uint256 i = 0; i < activeOracles.length; i++) {
            address oracleAddr = activeOracles[i];
            Oracle memory oracle = oracles[oracleAddr];
            weights[i] = oracle.reputation * oracle.stake / 1e18; // Normalize stake
            totalWeight += weights[i];
        }
        
        // Use pseudo-random selection weighted by reputation and stake
        uint256 seed = uint256(keccak256(abi.encodePacked(transactionId, block.timestamp, block.prevrandao)));
        
        for (uint256 j = 0; j < count; j++) {
            uint256 randomValue = uint256(keccak256(abi.encodePacked(seed, j))) % totalWeight;
            uint256 currentWeight = 0;
            
            for (uint256 i = 0; i < activeOracles.length; i++) {
                currentWeight += weights[i];
                if (randomValue < currentWeight && !isSelected(selected, activeOracles[i], j)) {
                    selected[j] = activeOracles[i];
                    break;
                }
            }
        }
        
        return selected;
    }
    
    function slashOracle(address oracle, uint256 amount) external override onlyDisputeResolution nonReentrant {
        require(oracles[oracle].isActive, "Oracle not active");
        
        Oracle storage oracleData = oracles[oracle];
        require(oracleData.stake >= amount, "Insufficient stake");
        
        oracleData.stake -= amount;
        totalStaked -= amount;
        
        // Burn slashed tokens or send to treasury
        require(nativeToken.transfer(owner(), amount), "Transfer failed");
        
        emit OracleSlashed(oracle, amount);
    }
    
    function rewardOracle(address oracle, uint256 amount) external override onlyDisputeResolution {
        require(oracles[oracle].isActive, "Oracle not active");
        require(amount > 0, "Invalid amount");
        
        // Mint reward tokens (assuming the contract has minting rights or tokens)
        require(nativeToken.transfer(oracle, amount), "Transfer failed");
        
        emit OracleRewarded(oracle, amount);
    }
    
    function getOracleStats(address oracle) external view override returns (Oracle memory) {
        return oracles[oracle];
    }
    
    function getActiveOraclesCount() external view returns (uint256) {
        return activeOracles.length;
    }
    
    function getActiveOracles() external view returns (address[] memory) {
        return activeOracles;
    }
    
    function getOracleAccuracy(address oracle) external view returns (uint256) {
        Oracle memory oracleData = oracles[oracle];
        if (oracleData.totalVotes == 0) return 0;
        return (oracleData.correctVotes * 100) / oracleData.totalVotes;
    }
    
    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }
    
    // Internal helper function
    function isSelected(address[] memory selected, address oracle, uint256 upToIndex) internal pure returns (bool) {
        for (uint256 i = 0; i < upToIndex; i++) {
            if (selected[i] == oracle) {
                return true;
            }
        }
        return false;
    }
    
    // Emergency functions
    function emergencyPause() external onlyOwner {
        // Pause oracle selection in emergency
    }
    
    function updateMinStake(uint256 newMinStake) external onlyOwner {
        require(newMinStake > 0, "Invalid min stake");
        // Update minimum stake requirement
    }
}
