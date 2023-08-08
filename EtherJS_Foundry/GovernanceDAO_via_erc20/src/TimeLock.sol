// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {GovernorTimelockControl, TimelockController} from "../lib/openzeppelin-contracts/contracts/governance/extensions/GovernorTimelockControl.sol";

contract TimeLock is TimelockController {

    // can see the TimeLockController's constructor 
    // minDelay is how long yu have to wait before execute
    // proposers is the list of addr that can propose
    // executors is the list of addr that can execute
    // admin we use "msg.sender" first, then we can shift and move to another address so the DAO can control it.
    constructor(uint256 minDelay, address[]  memory proposers, address[] memory executors)
    TimelockController(minDelay,proposers,executors, msg.sender) 
    {}
}