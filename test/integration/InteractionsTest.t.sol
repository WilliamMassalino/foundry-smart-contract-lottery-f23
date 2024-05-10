// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Script, console} from "forge-std/Script.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../../test/mocks/linkToken.sol";

/// @title Test Suite for the Interactions Scripts
/** 
 * @notice Tests the CreateSubscription, FundSubscription, and AddConsumer scripts for proper functionality.
 */
contract InteractionsTest is Test {
    VRFCoordinatorV2Mock vrfCoordinator;
    LinkToken linkToken;
    HelperConfig helperConfig;
    CreateSubscription createSubscription;
    FundSubscription fundSubscription;
    AddConsumer addConsumer;

    uint64 subscriptionId;
    uint256 deployerKey;

    function setUp() public {
        deployerKey = uint256(keccak256("key"));
        helperConfig = new HelperConfig();
        vrfCoordinator = new VRFCoordinatorV2Mock(0.1 ether, 1e9);
        linkToken = new LinkToken();

        // Set up HelperConfig with appropriate mock addresses and keys
        helperConfig.setConfig(
        0.01 ether, // entranceFee
        30, // interval
        address(vrfCoordinator), // vrfCoordinator
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // gasLane
        0, // subscriptionId, dynamically updated later
        50000, // callbackGasLimit
        address(linkToken), // link address
        deployerKey // deployerKey
    );

        createSubscription = new CreateSubscription();
        fundSubscription = new FundSubscription();
        addConsumer = new AddConsumer();
    }

    /// @notice Test the creation of a subscription via the CreateSubscription script
    function testCreateSubscription() public {
        uint64 _subId = createSubscription.createSubscription(address(vrfCoordinator), deployerKey);
        assertTrue(_subId > 0, "Subscription ID should be greater than zero");
    }


    /// @notice Test adding a consumer fails if the subscription does not exist
    function testFailToAddConsumerNonExistingSubscription() public {
        address raffle = address(new VRFCoordinatorV2Mock(0.1 ether, 1e9)); // Mock raffle contract
        vm.expectRevert("subId does not exist");
        addConsumer.addConsumerToSubscription(raffle, address(vrfCoordinator), 9999, deployerKey); // Non-existent subscription ID
    }
}