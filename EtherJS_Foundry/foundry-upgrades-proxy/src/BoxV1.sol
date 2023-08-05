// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
//import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
//import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

// IMPT: Storage is stored in the proxy, NOT in the implementation.
// Proxy (borrowing funcs) ->  from implementation
// if implmentation have a contractor that sets ( num = 1), the proxy's ( num = 0 ) still 0.
// so contracts that are meant to be use via proxies, don't use a constructor, instead, they use "initializer" function. it is like a constructor, but called from the proxy. 
// proxy -> deploy implementation -> call some "initialiser".
// therefore, constructors are not used in proxy contracts.

contract BoxV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 internal number;

    /// @custom:oz-upgrades-unsafe-allow constructor //sometimes lintere might say u are using a constructor in an upgradable contract, and u shouldn't do that.
    // but we want it to let it happen, because
    // this _diasableInitializer() does, is that it don't let any initialization happen
    // u you could also have just commented out, and removed this whole constructor part. Putting it here purely for more verbosity.
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        // write whatever we want to initialize, then we deploy the contract
        // then the proxy immediately call our initialized function. so it will get stored in the proxy contract. (instead of going to the constructor)
        // this upgradable initializable functions will be prepended with __
        __Ownable_init(); //sets the owner to: owner = msg.sender
        __UUPSUpgradeable_init(); //don't really need, doesn't do anything much, but best practise to put it in.
    }


    function getNumber() external view returns(uint256) {
        return number;
    }

    function version () external pure returns (uint256){
        return 1;
    }

    function _authorizeUpgrade(address newImplementation) internal override {
        // // anybody can update this, since there is nothing implemented

        // // if u wanna make checks such that only "owner can upgrade this"
        // if(msg.sender != owner) {
        //     revert; 
        // }
        // or we can also just add an onlyOwner Modifier here.
    }
}