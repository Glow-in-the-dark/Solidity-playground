// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol"; // import library

//Error Codes
error FundMe__NotOwner();

contract FundMe {

// Type declarations
// State Variables
// Events
// Modifiers
// Functions

    using PriceConverter for uint256; // declare library for dataType.

    uint256 public constant MINIMUM_USD = 50 * 1e18; // * 1e18 cuz require statement we are comparing with eth in "wei".
  
    address[] public s_funders;
    mapping(address => uint256)public s_addressToAmountFunded;

    address private immutable i_owner; 

    AggregatorV3Interface public s_priceFeed;

    // modifier onlyOwner {
    //     require(msg.sender == i_owner, "Sender is not Owner!");
    //     _; // This _; means run require the top code first (in this case, is the require statement), then the remaining code.
        
    //     // if it is:
    //     // 
    //     // _;
    //     // require(msg.sender == owner, "Sender is not Owner!");

    //     // then it means runs the func() code first, then run the "require" statement. (which in this case is not efficient.)
    // }

    modifier onlyOwner {
        if(msg.sender != i_owner) {revert FundMe__NotOwner();}
        _;
    }

// // Order of Functions ---
// constructor
// receive function (if exists)
// fallback function (if exists)
// external -  Cannot be accessed internally, only externally
// public - all can access
// internal - only this contract and contracts deriving from it can access
// private - can be accessed only from this contract
// view/pure

    constructor(address s_priceFeedAddress){
        i_owner = msg.sender; // so the owner will be the person deploying this contract
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    // But what if someone send this contract ETH without calling the "fund" function, then it is not recorded, and we cannot credit and keep track of them ? 
    // But there is a where such that when people "send" money, or people call a function that doesn't exist, for us to trigger some code.
    // 1. recieve()
    // 2. fallback()
    
    receive() external payable {
        fund();
    }
    fallback() external payable {
        fund();
    }

    // In this case, if ppl send $$ without using the fund() function, the recieve and fallback function will still trigger can automatically call the fund() function.

    function fund() public payable {
    // want to be able to set a minimum fund amt in USD
    // 1. How to we send ETH to this address
    require ( msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "you neeed to spend more ETH!"); // means if they send, it will have to me more than 1ETH.data, else it will revert.
    s_funders.push(msg.sender);
    s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public payable onlyOwner {

        // to do checks for owner, we can do this: ( but in this case, we use modifier, so we don't need to copy and paste all of these code)
        // require(msg.sender == owner); //check to make sure if it is called by owner.

        for (uint256 i = 0; i < s_funders.length; i++){
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        //reset array
        s_funders = new address[](0); // (0) means starting with 0 element inside
        
        // // Withdraw the funds ( 3 different ways ) 
        // // 1. Transfer 
        // payable(msg.sender).transfer(address(this).balance);

        // // 2. Send 
        // // payable(msg.sender).send(address(this).balance); // if it is just like this, if it fails, it will not revert, and won't get money sent.
        // // therefore we need to use require to revert here.
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess,"Send Failed");

        // 3. Call (most powerful, can call any function even without ABI)
        // call method return 2 values!
        // (bool callSuccess, bytes memory dataReturned ) = payable(msg.sender).call{value: address(this).balance}("");
        // but since we are not calling any function, and don't need the dataReturned, we can just do this
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed"); 
    }

    function cheaperWithdraw() public payable onlyOwner {
        address [] memory funders = s_funders;
        // mappings can't be in memory tho. 

        for (uint256 i = 0; i < funders.length; i++){
            address funder = funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0); //reset all to 0
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    // VIEW/PURE (GETTERS)

    function getOwner() public view returns(address) {
        return i_owner;
    }

    function getFunders(uint256 index) public view returns(address){
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder) public view returns(uint256){
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns(AggregatorV3Interface) {
        return s_priceFeed;
    }


}