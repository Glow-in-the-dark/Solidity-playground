// Raffle

// Enter the lottery ( pay some amount)
// Pick a random winnder (verifiably random) 

//winer to be selected every X mins -> completed automated.abi
// Chainlink Oracle -> randomess, Automated Execution (chainlink keeper)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol"; //We using the subscription method, not direct funding
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpKeepNotNeeded(uint256 currentBalance, uint256 numPlayers , uint256 raffleState);

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    } // same as (uint256 0 = OPEN, 1 = CALCULATING), but this is being more explicit

    /* State Variable */
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private immutable NUM_WORDS = 1;
    

    // Lottery Variables
    address private s_recentWinner;
    // uint256 private s_state; // 1 = pending, 2 = open, 3 = closed, 4 = calculating (while u can do this, it is better to use enums.)
    RaffleState private s_raffleState; // using the enum's method, to create new "TYPE"
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    /* Events */
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);


    constructor (
        address vrfCoordinatorV2, 
        uint256 entranceFee, 
        bytes32 gasLane, 
        uint64 subscriptionId, 
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN; // or u can also do  s_raffleState = RaffleState(0);
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    function enterRaffle() public payable {
        // require (msg.value > i_entranceFee, "Not enough ETH!") //Not as GAS efficient, because there is "string"
        if(msg.value < i_entranceFee){
            revert Raffle__NotEnoughETHEntered(); //More GAS efficient
            } 
        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__NotOpen();
            }
        s_players.push(payable (msg.sender));
        // EVENTS (whenever we update a dynamic object like arrays or mapping, we always want to emit an event. )
        // Named events with function name reverse.
        emit RaffleEnter(msg.sender);

    }

    /// @dev This is the function that the Chainlink Keeper nodes call
    /// They look for the`upkeepNeeded` to return true.
    /// The following should be true in order to return true.
    /// 1. Our time internal should have passed
    /// 2. The lottery should have at least 1 player, and have some ETH
    /// 3. Our subscription is funded with LINK
    /// 4. Lottery should be in an *open* state, and when it is requesting for a random number, it should be a *closed/calculating* state, to prevent people from joining during that time.
    function checkUpkeep(
        bytes memory /*checkData*/  //In this case we don't need to use any Data, but the input parameter of type bytes make it very flexible such that u can even input and call other functions()
        ) public override returns (bool upkeepNeeded , bytes memory /*performData */) {
            bool isOpen = (RaffleState.OPEN == s_raffleState);
            bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;// (block.timestamp - last block timestamp) > interval
            bool hasPlayers = (s_players.length > 0);
            bool hasBalance = address(this).balance > 0;
            upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance); // if all true, then request a random number.
        }

    // use Chainlink VRF & also Chainlink Keepers.
    function performUpkeep(bytes calldata /*performData*/)  external override {
        //request RND number
        // Once we get it, do something with it
        // 2 transaction process
        // Will revert if subscription is not set and funded.
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpKeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords( // we call the requestRandomWords() method from the interface.
            i_gasLane, // keyHash aka gasLane, thhe maximum gas price u willing to pay for a request in wei.
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS // how many random numbers we want to get
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256 /*requestId*/,  uint256[] memory randomWords) internal override {
        // use Modulo to get random number in array of dynamic size "x"
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN; // after calculating, open it back
        s_players = new address payable[](0); // After calculating, reset the player's array.
        s_lastTimeStamp = block.timestamp;
        // now that we have the address of the winner, now we need to send them the money.
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        //require(success)
        if(!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /* view / pure functions */
    function getEntranceFee() public view returns (uint256){
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns(address){
        return s_players[index];
    }

    function getRecentWinner() public view returns(address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns(RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns(uint256) {  // Pure because variable stored as constant
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns(uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp()  public view returns(uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmations()  public pure returns(uint256) { // Pure because variable stored as constant
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns(uint256){
        return i_interval;
    }
}