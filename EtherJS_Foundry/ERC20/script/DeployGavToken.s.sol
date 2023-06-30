// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {GavToken} from "../src/GavToken.sol";

contract DeployGavToken is Script {
    uint256 public constant INITIAL_SUPPLY = 1000 ether;

    function run() external returns(GavToken) {
        vm.startBroadcast();
        GavToken gt = new GavToken(INITIAL_SUPPLY);
        vm.stopBroadcast();
        return gt;
    }
}