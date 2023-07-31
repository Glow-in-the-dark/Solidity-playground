// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
//import {UUPSUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BoxV1 is UUPSUpgradeable {
    uint256 internal number;

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
    }
}