//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {BoxV1} from "../src/BoxV1.sol";
import {ERC1967Proxy} from "../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
//import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployBox is Script {
    function run() external returns(address){
        address proxy = deployBox();
        return proxy;
    }

    function deployBox() public returns(address){
        vm.startBroadcast();
        BoxV1 box = new BoxV1(); //implementation (logic)
        ERC1967Proxy proxy = new ERC1967Proxy(address(box),""); // ERC1967Proxy has a constructor
        // in the constructor, the "_logic" , refers to implementation contract addr, and "_data" refers to any data u wanna pass to the "initializer()",
        // but we not gonna have some initializer stuff, so we ignore the "_data" part.)
        vm.stopBroadcast();
        return address(proxy);
    }
}