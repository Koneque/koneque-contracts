// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/account/SmartAccountFactory.sol";

contract DeploySmartAccountFactoryScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy SmartAccountFactory
        SmartAccountFactory smartAccountFactory = new SmartAccountFactory();
        
        console.log("SmartAccountFactory deployed at:", address(smartAccountFactory));
        console.log("=====================================");
        console.log("SmartAccountFactory:", address(smartAccountFactory));
        console.log("=====================================");

        vm.stopBroadcast();
    }
}