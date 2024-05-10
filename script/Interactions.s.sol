// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/linkToken.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

/**
 * @title Chainlink Subscription Creation Script
 * @notice Handles the creation of Chainlink VRF subscriptions.
 * @dev Provides utility functions for creating and managing Chainlink VRF subscriptions.
 */
contract CreateSubscription is Script {
    /**
     * @dev Creates a new subscription for Chainlink VRF using the HelperConfig settings.
     * @return The ID of the newly created subscription.
     */
    function CreateSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, ,address vrfCoordinator, , , , ,uint256 deployerKey) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator, deployerKey);
    }

    /**
     * @dev Internal function to create a Chainlink VRF subscription.
     * @param vrfCoordinator Address of the Chainlink VRF Coordinator.
     * @param deployerKey Private key used for transaction signing.
     * @return subId The ID of the newly created subscription.
     */
    function createSubscription(address vrfCoordinator, uint256 deployerKey) public returns (uint64 subId) {
        console.log("Creating subscription on ChainId: ", block.chainid);
        vm.startBroadcast(deployerKey);
        subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your sub Id is: ", subId);
        console.log("Please update subscriptionId in HelperConfig.s.sol");
        return subId;
    }

    /**
     * @dev Script entry point for creating a subscription.
     * @return The ID of the newly created subscription.
     */
    function run() external returns (uint64) {
        return CreateSubscriptionUsingConfig();
    }
}

/**
 * @title Subscription Funding Script
 * @notice Provides functionality for funding a Chainlink VRF subscription.
 * @dev Script to fund a Chainlink VRF subscription with LINK tokens.
 */
contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    /**
     * @dev Funds a Chainlink VRF subscription using the configuration from HelperConfig.
     */
    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , uint64 subId, , address link, uint256 deployerKey) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subId, link, deployerKey);
    }

    /**
     * @dev Funds a subscription at the specified address with the provided amount of LINK.
     * @param vrfCoordinator Address of the VRF Coordinator.
     * @param subId Subscription ID to fund.
     * @param link Address of the LINK token contract.
     * @param deployerKey Private key for transaction signing.
     */
    function fundSubscription(address vrfCoordinator, uint64 subId, address link, uint256 deployerKey) public {
        console.log("Funding subscription: ", subId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);
        if (block.chainid == 31337) {
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerKey);
            LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    /**
     * @dev Script entry point for funding a subscription.
     */
    function run() external {
        fundSubscriptionUsingConfig();
    }
}

/**
 * @title Add Consumer to Subscription Script
 * @notice Adds a consumer contract to a Chainlink VRF subscription.
 * @dev Script to manage adding consumer contracts to existing Chainlink VRF subscriptions.
 */
contract AddConsumer is Script {
    /**
     * @dev Adds a raffle contract as a consumer to a Chainlink VRF subscription.
     * @param raffle Address of the Raffle contract.
     * @param vrfCoordinator Address of the VRF Coordinator.
     * @param subId Subscription ID where the consumer will be added.
     * @param deployerKey Private key for transaction signing.
     */
    function addConsumerToSubscription(address raffle, address vrfCoordinator, uint64 subId, uint256 deployerKey) public {
        console.log("Adding consumer contract: ", raffle);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, raffle);
        vm.stopBroadcast();
    }

    /**
     * @dev Adds a consumer using the configuration from HelperConfig and a specified raffle address.
     * @param raffle Address of the Raffle contract to be added as a consumer.
     */
    function AddConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , uint64 subId, , , uint256 deployerKey) = helperConfig.activeNetworkConfig();
        addConsumerToSubscription(raffle, vrfCoordinator, subId, deployerKey);
    }

    /**
     * @dev Script entry point for adding a consumer to a subscription.
     */
    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        AddConsumerUsingConfig(raffle);
    }
}
