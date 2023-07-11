// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions


pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
*@title DSCEngine
*@author Gavin
*The system is designed to me minimal, and token maitain a 1 token = $1 peg
* Similar to DAI if DAI had no governance, no fees and backed by wETH and wBTC
* 
* Our DSC system should always be "overcollateralized", At no point should the valye of all collateral <= the $ backed value of all the DSC.
*
*@notice This contract is the core of the DSC system. It handles all the logic for mining and redeeming DSC as well as deposting & withdrawing collateral.
*@notice This contract is VERY loosely based on Makerdao DAI system.
*/
contract DSCEngine is ReentrancyGuard{
    ///////////////////
    // Errors
    ///////////////////
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenNotAllowed(address token);
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactorValue);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();

    ///////////////////
    // State Variables
    ///////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // 50% liquidation threshold = 200% overcollateralized
    uint256 private constant LIQUIDATION_PRECISION = 100; // * 100, so we don't deal with decimals
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private s_priceFeeds; // tokenToPriceFeed
    DecentralizedStableCoin private immutable i_dsc;
    // tracks how much collateral someone deposits
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_DSCMinted;

    address[] private s_collateralTokens; //store the list of contract address (wETH/wBTC)

    ///////////////////
    // Events
    ///////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    ///////////////////
    // Modifiers
    ///////////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__TokenNotAllowed(token);
        }
        _;
    }

    ///////////////////
    // Functions
    ///////////////////
    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address dscAddress
    ) {
        // USD Price Feeds
        if(tokenAddresses.length != priceFeedAddresses.length){
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }
        // For example BTC/USD, ETH/USD, MKR/USD, etc.
        for (uint256 i = 0; 1< tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    ///////////////////
    // External Functions
    ///////////////////

    function depositCollateralAndMintDsc() external {}

    /*
    * @param tokenCollateralAddress: The address of the token to deposit as collateral
    * @param amountCollateral: The amt of collateral to deposit.
    */
    function depositCollateral(
        address tokenCollateralAddress, 
        uint256 amountCollateral
    ) external  
        moreThanZero(amountCollateral) 
        isAllowedToken(tokenCollateralAddress) 
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress]+= amountCollateral;
        // since we are updating state, we should emit and event.
        emit CollateralDeposited(msg.sender,tokenCollateralAddress,amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender,address(this),amountCollateral);
        if(!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDsc() external {}
    
    function redeemCollateral() external {}
    
    /*
    * @param amountDscToMint: The amt of DSC token to "mint"
    * @notice they must have more collateral value than the minimum threshold. Also check if the collateral value > DSC amount. Price Feeds, values ....
    */
    function mintDsc(uint256 amountDscToMint) external moreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint;
        // if they minted too much($150 DSC, with $100ETH. Then must revert)
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if(!minted) {
            revert DSCEngine__MintFailed();
        }
    }
    
    function burnDsc() external {}
    
    function liquidate() external {}
    
    function getHealthFactor() external view {}

    //////////////////////
    // Private & Internal Functions
    //////////////////////

    function _getAccountInformation(address user) 
        private 
        view 
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd) 
    {
        totalDscMinted = s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    /*
    * returns how close to liquidation a user is. 
    * If a user goes below 1, then they can get liquidated.
    */
    function _healthFactor(address user) private view returns(uint256) {
        // total DSC minted
        // total collateral VALUE
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        // return collateralValueInUsd / totalDscMinted //(not correct because never adjust for overcollateral's safety margin)
        // 
        // $15 ETH / 10 DSC = 1.5
        // 15 * 50 = 750; 750 / 100 = $7.5 (adjusted collateral)
        // $7.5/ $10  = 0.75 (adjusted Collateral/ DSC minted)  =< 1 means can be liquidated
        //  
        // $100 ETH / 10 DSC
        // $100(ETH) * 50 = $5,000; 5,000 / 100 = 50 (adjusted collateral)
        // $50/$10 = 5
        uint256 collateralAdjustedForTheshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION; 
        return (collateralAdjustedForTheshold * PRECISION) / totalDscMinted;
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        // 1. Check health factor ( do they have enough collateral?)
        // 2. Revert if they don't 
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    //////////////////////
    // Public & External View Functions
    //////////////////////
    function getAccountCollateralValue(address user) public view returns(uint256 totalCollateralValueInUsd){
        //loop through each collateral token, and get the amount they have deposited,
        // and map it to ther price, to get the USD value   
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token,amount);
        }
        return totalCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (,int256 price,,,) = priceFeed.latestRoundData();
        // 1ETH = $1000, 
        // The return value will be 1000 * 1e8
        // And since the amount unit precision is in 1e18 , we need to recalibrate it
        return ((uint256(price)*ADDITIONAL_FEED_PRECISION)* amount) / PRECISION;
    }

}