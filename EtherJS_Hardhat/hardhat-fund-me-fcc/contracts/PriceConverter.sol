// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; //import directly from Github, //remix knows that @chainlink/contracts referrs to the NPM package "@chainlink/contracts"

library PriceConverter {

    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {  
    
        // (uint80 roundId, int price, uint startedAt, uint timestamp, uint answeredInRound) = priceFeed.latestRoundData();
        (,int256 price,,, ) = priceFeed.latestRoundData();
        // Eth price given in terms of USD (8 decimals )
        // uint256 decimals = priceFeed.decimals();
        //since wei is 1e18, and decimals is "8" we need to * 1e10.
        return uint256(price * 1e10);
    }

  
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount)/1e18;
        return ethAmountInUsd;
    }
 
}