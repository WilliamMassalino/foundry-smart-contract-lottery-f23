// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title Raffle Contract
 * @notice Implements a raffle system using Chainlink VRF (Verifiable Random Function) to ensure fair selection of a winner.
 * @dev Inherits VRFConsumerBaseV2 for interacting with Chainlink VRF.
 * @author William Massalino
 */
contract Raffle is VRFConsumerBaseV2 {
    // Custom errors for handling specific revert cases
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    /**
     * @dev Sets initial raffle configuration upon contract deployment.
     * @param entranceFee Minimum ETH required to enter the raffle.
     * @param interval The minimum time between raffles.
     * @param vrfCoordinator Address of the Chainlink VRF Coordinator.
     * @param gasLane The key hash used by Chainlink to select the specific gas lane.
     * @param subscriptionId Chainlink subscription ID for funding VRF requests.
     * @param callbackGasLimit Gas limit for the callback function handling the VRF response.
     */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
    }

    /**
     * @notice Allows a player to enter the raffle, requiring a payment of the entrance fee.
     */
    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /**
     * @notice Determines if the raffle is ready to draw a winner.
     * @dev Checks if enough time has passed, if the raffle is open, if there is enough balance, and if there are players.
     * @return upkeepNeeded True if all conditions are met, false otherwise.
     */
    function checkUpkeep(bytes memory /*checkData*/
    ) public view returns (bool upkeepNeeded, bytes memory /*performData*/) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    /**
     * @notice Initiates the process to randomly select a winner.
     * @dev Only callable when `checkUpkeep` returns true. Requests randomness from Chainlink VRF.
     */
    function performUpkeep(bytes calldata /*performData */) external {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    /**
     * @dev Callback function used by VRF Coordinator to return the random number.
     * @param requestId The ID of the VRF request.
     * @param randomWords Array containing the random result provided by VRF.
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0) ;
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit PickedWinner(winner);
    }

    /** Getter Functions */

    /**
     * @notice Returns the entrance fee of the raffle.
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    /**
     * @notice Returns the current state of the raffle.
     */
    function getRaffleState() external view returns (RaffleState){
        return s_raffleState;
    }
    
    /**
     * @notice Returns the address of a player by index.
     */
    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }

    /**
     * @notice Returns the address of the most recent winner.
     */
    function getRecentWinner() external view returns(address) {
        return s_recentWinner;
    }

    /**
     * @notice Returns the total number of players entered in the raffle.
     */
    function getLengthOfPlayers() external view returns(uint256) {
        return s_players.length;
    }

    /**
     * @notice Returns the timestamp of the last raffle.
     */
    function getLastTimeStamp() external view returns(uint256) {
        return s_lastTimeStamp;
    }
}
