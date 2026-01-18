// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Crowdfunding} from "../src/Crowdfunding.sol";

/**
 * @title Deploy
 * @notice Deployment script for the Crowdfunding contract
 * @dev Run with: forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
 */
contract Deploy is Script {
    function run() external returns (Crowdfunding crowdfunding) {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the Crowdfunding contract
        crowdfunding = new Crowdfunding();

        // Stop broadcasting
        vm.stopBroadcast();

        // Log deployment info
        console.log("Crowdfunding deployed to:", address(crowdfunding));
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Block number:", block.number);
        console.log("Block timestamp:", block.timestamp);

        return crowdfunding;
    }
}