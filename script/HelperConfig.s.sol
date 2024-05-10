// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/linkToken.sol";

/**
 * @title Helper Configuration for Network Settings
 * @notice Manages network-specific configurations for the Raffle contract deployment.
 * @dev This contract stores configurations and assists other scripts in obtaining network-specific parameters.
 */
contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        uint256 deployerKey;
    }

    uint256 public constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function setConfig(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        address link,
        uint256 deployerKey
    ) public {
        activeNetworkConfig = NetworkConfig({
            entranceFee: entranceFee,
            interval: interval,
            vrfCoordinator: vrfCoordinator,
            gasLane: gasLane,
            subscriptionId: subscriptionId,
            callbackGasLimit: callbackGasLimit,
            link: link,
            deployerKey: deployerKey
        });
    }

    /**
     * @notice Retrieves the predefined network configuration for Sepolia testnet.
     * @return A NetworkConfig structure with the Sepolia settings.
     */
    function getSepoliaEthConfig() public view returns(NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0, // Update this with actual subscription ID!
            callbackGasLimit: 50000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    /**
     * @notice Creates or retrieves the network configuration for Anvil local environment.
     * @dev This function creates mock instances for testing purposes if not already configured.
     * @return A NetworkConfig structure with Anvil settings.
     */
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory){
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }
        uint96 baseFee = 0.25 ether; // 0.25 LINK
        uint96 gasPriceLink = 1e9; // 1 gwei LINK

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0, // Subscription ID to be set up
            callbackGasLimit: 50000,
            link: address(link),
            deployerKey: DEFAULT_ANVIL_KEY
        });
    }
}
