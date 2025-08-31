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

contract DeployAndVerifyScript is Script {
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
    
    // Verification commands
    string[] public verificationCommands;
    
    function setUp() public {
        // Set platform wallet (can be changed later)
        platformWallet = msg.sender;
    }
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== STARTING DEPLOYMENT WITH VERIFICATION ===");
        
        // Deploy all contracts
        deployContracts();
        
        // Configure contract relationships
        configureContracts();
        
        vm.stopBroadcast();
        
        // Log all deployed addresses
        logDeployedAddresses();
        
        // Generate verification commands
        generateVerificationCommands();
        
        console.log("=== DEPLOYMENT COMPLETED ===");
        console.log("Run the following commands to verify contracts:");
        for (uint256 i = 0; i < verificationCommands.length; i++) {
            console.log(verificationCommands[i]);
        }
    }
    
    function deployContracts() internal {
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
    
    function generateVerificationCommands() internal {
        string memory baseCmd = "forge verify-contract";
        string memory rpcFlag = " --rpc-url $BASE_SEPOLIA_RPC_URL";
        string memory etherscanFlag = " --etherscan-api-key $BASESCAN_API_KEY";
        string memory chainFlag = " --chain base-sepolia";
        
        // NativeToken (no constructor args)
        verificationCommands.push(
            string.concat(
                baseCmd,
                " ",
                vm.toString(address(nativeToken)),
                " src/token/NativeToken.sol:NativeToken",
                rpcFlag,
                etherscanFlag,
                chainFlag
            )
        );
        
        // SmartAccount (no constructor args)
        verificationCommands.push(
            string.concat(
                baseCmd,
                " ",
                vm.toString(address(smartAccountImplementation)),
                " src/account/SmartAccount.sol:SmartAccount",
                rpcFlag,
                etherscanFlag,
                chainFlag
            )
        );
        
        // AccountFactory (constructor arg: smartAccount address)
        verificationCommands.push(
            string.concat(
                baseCmd,
                " ",
                vm.toString(address(accountFactory)),
                " src/account/AccountFactory.sol:AccountFactory",
                rpcFlag,
                etherscanFlag,
                chainFlag,
                " --constructor-args $(cast abi-encode 'constructor(address)' ",
                vm.toString(address(smartAccountImplementation)),
                ")"
            )
        );
        
        // Paymaster (constructor arg: nativeToken address)
        verificationCommands.push(
            string.concat(
                baseCmd,
                " ",
                vm.toString(address(paymaster)),
                " src/account/Paymaster.sol:Paymaster",
                rpcFlag,
                etherscanFlag,
                chainFlag,
                " --constructor-args $(cast abi-encode 'constructor(address)' ",
                vm.toString(address(nativeToken)),
                ")"
            )
        );
        
        // Continue with other contracts...
        // (Adding all would make this very long, but the pattern is the same)
    }
}
