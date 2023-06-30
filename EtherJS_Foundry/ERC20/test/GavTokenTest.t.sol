// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from"forge-std/Test.sol";
import {DeployGavToken} from "../script/DeployGavToken.s.sol";
import {GavToken} from "../src/GavToken.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract GavTokenTest is StdCheats, Test {
    GavToken public gavToken;
    DeployGavToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    uint256 public constant STARTING_BALANCE = 200 ether;

    function setUp() public {
        deployer = new DeployGavToken();
        gavToken = deployer.run();

        vm.prank(msg.sender);
        gavToken.transfer(bob, STARTING_BALANCE);
        console.log("_msgSender", msg.sender);
        console.log("DeployerContractAddress:", address(deployer)); 
        // deployer is of type DeployGavToken, which is a contract, and the console.log function does not support logging contracts directly.
        // By using address(deployer), you are casting the contract to its address type, which is supported by the console.log function.
        console.log("GavTokenAddress:", address(gavToken));
        console.log("GavTokenTest/address(this):", address(this));

    }

    function testBobBalance() public {
        assertEq(STARTING_BALANCE, gavToken.balanceOf(bob));
    }

    function testAllowancesWorks() public {
        //transferFrom
        uint256 initialAllowance = 1000;

        //Bob approves Alice to spend tokens on his behalf
        vm.prank(bob);
        gavToken.approve(alice,initialAllowance); // calls the approve function of gavToken, which inherits the ERC20 token that has the approve()
        // sometimes no need to explicitly approve anything? (no need to explicitly approve other people to use your tokens)? But good to have to contract can keep track of how mnay token we sent.abi

        uint256 transferAmount = 500;

        vm.prank(alice);
        gavToken.transferFrom(bob,alice,transferAmount);
        assertEq(gavToken.balanceOf(alice),transferAmount);
        assertEq(gavToken.balanceOf(bob),STARTING_BALANCE-transferAmount);

    }

     function testTransfer() public {
        uint256 amount = 100;
        address recipient = address(this);
        uint256 initialSenderBalance = gavToken.balanceOf(msg.sender);
        uint256 initialRecipientBalance = gavToken.balanceOf(recipient);

        vm.prank(msg.sender);
        assertTrue(gavToken.transfer(recipient, amount));

        uint256 finalSenderBalance = gavToken.balanceOf(msg.sender);
        uint256 finalRecipientBalance = gavToken.balanceOf(recipient);

        assertEq(finalSenderBalance, initialSenderBalance - amount);
        assertEq(finalRecipientBalance, initialRecipientBalance + amount);
    }

    function testTransferExceedingBalance() public {
        uint256 amount = deployer.INITIAL_SUPPLY() + 1;
        address recipient = address(this);

        vm.expectRevert();
        gavToken.transfer(recipient, amount);
    }

    function testApproveAndAllowance() public {
        uint256 amount = 100;
        address spender = makeAddr('charlie');

        vm.prank(msg.sender);
        assertTrue(gavToken.approve(spender, amount));
        assertEq(gavToken.allowance(msg.sender, spender), amount);
    }

    function testTransferFrom() public {
        uint256 amount = 50 ;
        address recipient = makeAddr("recipient");
        uint256 initialBobBalance = gavToken.balanceOf(bob);
        uint256 initialRecipientBalance = gavToken.balanceOf(recipient);

        vm.prank(bob);
        gavToken.approve(recipient, amount);

        console.log("initialBobBalance",initialBobBalance);
        console.log("initialRecipientBalance",initialRecipientBalance );
        console.log("BobAllowanceToRecipient :",gavToken.allowance(bob,recipient));

        vm.prank(recipient);
        assertTrue(gavToken.transferFrom(bob, recipient, amount));

        uint256 finalBobBalance = gavToken.balanceOf(bob);
        uint256 finalRecipientBalance = gavToken.balanceOf(recipient);

        assertEq(finalBobBalance, initialBobBalance - amount);
        assertEq(finalRecipientBalance, initialRecipientBalance + amount);
    }

    function testTransferFromExceedingAllowance() public {
        uint256 amount = 100;
        uint256 exceedingAmount = 101;
        address tom = makeAddr("tom");

        vm.prank(bob);
        assertTrue(gavToken.approve(tom, amount)); // bob approve Tom

        // console.log("balanceOf bob:",gavToken.balanceOf(bob)/ 1 ether);
        // console.log("allowance Tom:",gavToken.allowance(tom,bob));
        // console.log("allowance bob:",gavToken.allowance(bob,tom));

        vm.prank(tom);
        vm.expectRevert();
        gavToken.transferFrom(bob, tom, exceedingAmount);
    }

}