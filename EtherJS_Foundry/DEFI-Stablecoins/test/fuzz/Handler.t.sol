// SPDX-License-Identifier: MIT

// Handler is going to narrow down the way we call function

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol"; //for testing priceFeeds portion

// not just our DSCEngine, we can test out other contracts that we interact with, like:
// PriceFeed
// WETH Token
// WBTC Token

contract Handler is Test {
    DSCEngine dsce;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    uint256 public timesMintIsCalled;
    address[] public usersWithCollateralDeposited;
    MockV3Aggregator public ethUsdPriceFeed;

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;

    constructor(DSCEngine _dscEngine, DecentralizedStableCoin _dsc) {
        dsce = _dscEngine;
        dsc = _dsc;

        address[] memory collateralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);

        // for testing priceFeeds portion
        ethUsdPriceFeed = MockV3Aggregator(dsce.getCollateralTokenPriceFeed(address(weth)));
    }

    function mintDsc(uint256 amount, uint256 addressSeed) public {
        if(usersWithCollateralDeposited.length == 0) {
            return;
        }
        address sender = usersWithCollateralDeposited[addressSeed % usersWithCollateralDeposited.length];
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(sender);
        
        uint256 maxDscToMint = (collateralValueInUsd / 2) - totalDscMinted;
        if (maxDscToMint < 0) {
            return;
        }
        amount = bound(amount,0, uint256(maxDscToMint));
        if (amount == 0) {
            return;
        }
        vm.startPrank(sender);
        dsce.mintDsc(amount);
        vm.stopPrank();
        timesMintIsCalled++; // keep moving this line up until u find out where the issue is // issue is Fuzzing will call from all kinds of address
        // The issue arise because, it is impossible for someone to mint something, if they didn't deposit collateral.
        // but maybe there is acase where u can mint DSC without depositing any collateral which we don't know about. tt's why it's impt to have some OpenInvariantTest, and some continueOnRevert & FailOnRevert.
        // if we want to to be FailOnRevent, then we would need to only pick a msg.sender, that had some deposited collateral.
        // so what we can do is to keep track of ppl who have deposited collateral and then when we go mint, we choose from an address from someone who has deposited.
    }

    //redeem collateral <-
    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public { //fuzz test would then input all the random data into these 2 parameters.
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender,amountCollateral);
        collateral.approve(address(dsce),amountCollateral);
        dsce.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
        // might double push, if same address used twice
        usersWithCollateralDeposited.push(msg.sender);
    }

    function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public { //fuzz test would then input all the random data into these 2 parameters.
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateralToRedeem = dsce.getCollateralBalanceOfUser(msg.sender, address(collateral));
        amountCollateral = bound(amountCollateral, 0, maxCollateralToRedeem);

        if (amountCollateral == 0) { // if 0, then return and don't call the dsce.redeemCollateral() below
            return;
        }
        vm.startPrank(msg.sender);
        dsce.redeemCollateral(address(collateral), amountCollateral); 
        vm.stopPrank();
    }

    // // This Breaks our invariant test suite, ( it shows that if in a single block, if price of collateral suddendly plummets very low, there will be debt, and not be able to pay out all the DSC )
    // // Checking priceFeed Portion
    // function updateCollateralPrice(uint96 newPrice) public {
    //     int256 newPriceInt = int256(uint256(newPrice));
    //     ethUsdPriceFeed.updateAnswer(newPriceInt);
    // }

    // Helper Functions
    function _getCollateralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock){
        if (collateralSeed % 2 == 0) {
            return weth;
        }
        return wbtc; // otherwise return wbtc
    }

}