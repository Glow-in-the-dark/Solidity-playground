//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {BoxV2} from "../src/BoxV2.sol";
import {BoxV1} from "../src/BoxV1.sol";

contract UpgradeBox is Script {
    function run() external returns(address){
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("ERC1967Proxy", block.chainid);
    
        vm.startBroadcast();
        BoxV2 newBox = new BoxV2();
        vm.stopBroadcast();
        // "mostRecentlyDeployed" <-- this is the proxy address.
        address proxy = upgradeBox(mostRecentlyDeployed, address(newBox));
        return proxy;
    }

    function upgradeBox(address proxyAddress, address newImplementationContract) public returns(address) {
        vm.startBroadcast();
        BoxV1 proxy = BoxV1(proxyAddress); // we give our proxy address, the boxV1 ABI
        // then now we can just use "proxy.upgradeTo()", because BoxV1 is "UUPSUpgradable", therefore we have access to this function.
        proxy.upgradeTo(address(newImplementationContract)); // proxy contract now points to this new address 
        vm.stopBroadcast();
        return address(proxy);
    } 

}