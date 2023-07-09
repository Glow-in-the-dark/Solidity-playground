// SPDX-License-Identifier: MIT
// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

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

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
/*
* @title DecentralizedStableCoin
* @author Gavin
* Collateral: (extrogenous (wETH, wBTC)
* Relative Stability: Pegged to USD
*
*
*This contract is meant to be governed by DSCEngine. This contract is just the ERC20 implmentation of our Stablecoin system
*/
contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    error DecentralizedStableCoin__MustBeMoreThanZero();
    error DecentralizedStableCoin__BurnAmountExceedsBalance();
    error DecentralizedStableCoin__NotZeroAddress();

    constructor () ERC20 ("DecentralizedStableCoin","DSC") Ownable(_msgSender()) {
    }

    function burn(uint256 _amount) public override onlyOwner { //overhere, we override the original burn function, as we want to implement more checks and stuff inside
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0){
            revert DecentralizedStableCoin__MustBeMoreThanZero();
        }
        if (balance < _amount){
            revert DecentralizedStableCoin__BurnAmountExceedsBalance();
        }
        super.burn(_amount); //overhere, we then run the original parent burn() function which we inherited from.
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns(bool){
        if(_to == address(0)) {
            revert DecentralizedStableCoin__NotZeroAddress();
        }
        if(_amount <= 0) {
            revert DecentralizedStableCoin__MustBeMoreThanZero();
        }
        _mint(_to,_amount);
        return true;
    }    
}