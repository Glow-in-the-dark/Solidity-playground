//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DeployBox} from "../script/DeployBox.s.sol";
import {UpgradeBox} from "../script/UpgradeBox.s.sol";
import {BoxV1} from "../src/BoxV1.sol";
import {BoxV2} from "../src/BoxV2.sol";

contract DeployAndUpgradeTest is Test {
    DeployBox public deployer;
    UpgradeBox public upgrader;
    address public OWNER = makeAddr("owner");
    address public proxy;

    function setUp() public {
        deployer = new DeployBox();
        upgrader = new UpgradeBox();
        proxy = deployer.run(); // returns u the address of the proxy, not addr of boxV1 ( which points to boxV1 currently)
    }

    function testBoxWorks() public {
        address proxyAddress = deployer.deployBox();
        uint256 expectedValue = 1;
        assertEq(expectedValue, BoxV1(proxyAddress).version());
    }

    function testProxyStartsAsBoxV1() public {
        vm.expectRevert();
        BoxV2(proxy).setNumber(7); // expectRevert, because BoxV1 don't have the .setNumber() 
    }

    function testUpgrades() public {
        BoxV2 box2 = new BoxV2();
        upgrader.upgradeBox(proxy,address(box2));

        uint256 expectedValue = 2;
        assertEq(expectedValue, BoxV2(proxy).version()); // if this is true, means proxy already pointing to boxV2

        // alternative we can also do this
        BoxV2(proxy).setNumber(7);
        assertEq(7,BoxV2(proxy).getNumber());
    }
}