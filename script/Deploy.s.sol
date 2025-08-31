// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/token/NativeToken.sol";
import "../src/account/AccountFactory.sol";
import "../src/account/SmartAccount.sol";
import "../src/account/Paymaster.sol";
import "../src/marketplace/MarketplaceCore.sol";
import "../src/marketplace/Escrow.sol";
import "../src/marketplace/FeeManager.sol";
import "../src/dispute/DisputeResolution.sol";
import "../src/dispute/OracleRegistry.sol";
import "../src/incentives/ReferralSystem.sol";

contract DeployScript is Script {
    // Deployed contract addresses
    NativeToken public nativeToken;
    SmartAccount public smartAccountImplementation;
    AccountFactory public accountFactory;
    Paymaster public paymaster;
    MarketplaceCore public marketplaceCore;
    Escrow public escrow;
    FeeManager public feeManager;
    DisputeResolution public disputeResolution;
    OracleRegistry public oracleRegistry;
    ReferralSystem public referralSystem;
    
    address public platformWallet;
    
    function setUp() public {
        // Set platform wallet (can be changed later)
        platformWallet = msg.sender;
    }
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy Native Token
        console.log("Deploying NativeToken...");
        nativeToken = new NativeToken();
        console.log("NativeToken deployed at:", address(nativeToken));
        
        // 2. Deploy SmartAccount Implementation
        console.log("Deploying SmartAccount implementation...");
        smartAccountImplementation = new SmartAccount();
        console.log("SmartAccount implementation deployed at:", address(smartAccountImplementation));
        
        // 3. Deploy AccountFactory
        console.log("Deploying AccountFactory...");
        accountFactory = new AccountFactory(address(smartAccountImplementation));
        console.log("AccountFactory deployed at:", address(accountFactory));
        
        // 4. Deploy Paymaster
        console.log("Deploying Paymaster...");
        paymaster = new Paymaster(address(nativeToken));
        console.log("Paymaster deployed at:", address(paymaster));
        
        // 5. Deploy Escrow
        console.log("Deploying Escrow...");
        escrow = new Escrow(address(nativeToken));
        console.log("Escrow deployed at:", address(escrow));
        
        // 6. Deploy FeeManager
        console.log("Deploying FeeManager...");
        feeManager = new FeeManager(address(nativeToken), platformWallet);
        console.log("FeeManager deployed at:", address(feeManager));
        
        // 7. Deploy MarketplaceCore
        console.log("Deploying MarketplaceCore...");
        marketplaceCore = new MarketplaceCore(address(nativeToken));
        console.log("MarketplaceCore deployed at:", address(marketplaceCore));
        
        // 8. Deploy DisputeResolution
        console.log("Deploying DisputeResolution...");
        disputeResolution = new DisputeResolution(address(nativeToken));
        console.log("DisputeResolution deployed at:", address(disputeResolution));
        
        // 9. Deploy OracleRegistry
        console.log("Deploying OracleRegistry...");
        oracleRegistry = new OracleRegistry(address(nativeToken));
        console.log("OracleRegistry deployed at:", address(oracleRegistry));
        
        // 10. Deploy ReferralSystem
        console.log("Deploying ReferralSystem...");
        referralSystem = new ReferralSystem(address(nativeToken));
        console.log("ReferralSystem deployed at:", address(referralSystem));
        
        // Configure contract relationships
        configureContracts();
        
        vm.stopBroadcast();
        
        // Log all deployed addresses
        logDeployedAddresses();
    }
    
    function configureContracts() internal {
        console.log("Configuring contract relationships...");
        
        // Configure MarketplaceCore
        marketplaceCore.setEscrowContract(address(escrow));
        marketplaceCore.setFeeManager(address(feeManager));
        
        // Configure Escrow
        escrow.setMarketplaceCore(address(marketplaceCore));
        escrow.setDisputeResolution(address(disputeResolution));
        
        // Configure FeeManager
        feeManager.setMarketplaceCore(address(marketplaceCore));
        feeManager.setReferralSystem(address(referralSystem));
        
        // Configure DisputeResolution
        disputeResolution.setOracleRegistry(address(oracleRegistry));
        disputeResolution.setEscrowContract(address(escrow));
        disputeResolution.setMarketplaceCore(address(marketplaceCore));
        
        // Configure ReferralSystem
        referralSystem.setFeeManager(address(feeManager));
        referralSystem.setMarketplaceCore(address(marketplaceCore));
        
        console.log("Contract configuration completed!");
    }
    
    function logDeployedAddresses() internal view {
        console.log("\n=== DEPLOYED CONTRACT ADDRESSES ===");
        console.log("NativeToken:", address(nativeToken));
        console.log("SmartAccount Implementation:", address(smartAccountImplementation));
        console.log("AccountFactory:", address(accountFactory));
        console.log("Paymaster:", address(paymaster));
        console.log("MarketplaceCore:", address(marketplaceCore));
        console.log("Escrow:", address(escrow));
        console.log("FeeManager:", address(feeManager));
        console.log("DisputeResolution:", address(disputeResolution));
        console.log("OracleRegistry:", address(oracleRegistry));
        console.log("ReferralSystem:", address(referralSystem));
        console.log("=====================================\n");
    }
    
    // Helper function to mint initial tokens for testing
    function mintInitialTokens(address[] memory recipients, uint256[] memory amounts) external {
        require(recipients.length == amounts.length, "Array length mismatch");
        
        vm.startBroadcast();
        for (uint256 i = 0; i < recipients.length; i++) {
            nativeToken.mint(recipients[i], amounts[i]);
        }
        vm.stopBroadcast();
    }
}

// Separate script for testing setup
contract SetupTestingScript is Script {
    function run() public {
        // Load deployed addresses (you would typically read these from a file or environment)
        address nativeTokenAddress = vm.envAddress("NATIVE_TOKEN_ADDRESS");
        
        vm.startBroadcast();
        
        NativeToken nativeToken = NativeToken(nativeTokenAddress);
        
        // Mint tokens for testing
        address[] memory testUsers = new address[](5);
        testUsers[0] = 0x1234567890123456789012345678901234567890; // Example addresses
        testUsers[1] = 0x2345678901234567890123456789012345678901;
        testUsers[2] = 0x3456789012345678901234567890123456789012;
        testUsers[3] = 0x4567890123456789012345678901234567890123;
        testUsers[4] = 0x5678901234567890123456789012345678901234;
        
        for (uint256 i = 0; i < testUsers.length; i++) {
            nativeToken.mint(testUsers[i], 100000 * 10**18); // 100,000 tokens each
        }
        
        vm.stopBroadcast();
        
        console.log("Testing setup completed!");
    }
}
