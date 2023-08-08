// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {GovToken} from "../src/GovToken.sol";
import {Box} from "../src/Box.sol";
import {TimeLock} from "../src/TimeLock.sol";



contract MyGovernorTest is Test {
    MyGovernor governor;
    Box box;
    TimeLock timelock;
    GovToken govToken;

    address public USER = makeAddr("user");
    uint256 public constant INITIAL_SUPPLY = 100 ether; //ether as in 1e18 ?

    uint256 public constant VOTING_PERIOD = 50400; // This is how long voting lasts
    uint256 public constant VOTING_DELAY = 10; // How many blocks till a proposal vote becomes active //see "MyGovernor.sol" 's GovernorSettings. ( Or see via OpenZeppelin's wizard)
    uint256 public constant MIN_DELAY = 3600; // 1 hour - after a vote passes, you have 1 hour before you can enact
    uint256 public constant QUORUM_PERCENTAGE = 4; // Need 4% of voters to pass

    address[] proposers;
    address[] executors;

    uint256[] values;
    bytes[] calldatas; //AKA functionCalls;
    address[] targets; // AKA addressesToCall


    function setUp() public {
        govToken = new GovToken();
        govToken.mint(USER, INITIAL_SUPPLY); // now USER have xxx Tokens

        vm.startPrank(USER);
        // while we the tokens, we delegate to ourselves, could also have delegated to others if u want.
        govToken.delegate(USER);

        timelock = new TimeLock(MIN_DELAY, proposers, executors);
        governor = new MyGovernor(govToken, timelock); //deploy governor contract

        // these are all hashes.. in the timelock contract, that refers to some "address"
        bytes32 proposerRole = timelock.PROPOSER_ROLE(); 
        bytes32 executorRole = timelock.EXECUTOR_ROLE(); 
        bytes32 adminRole = timelock.TIMELOCK_ADMIN_ROLE(); // that's us.

        timelock.grantRole(proposerRole, address(governor)); //allow this proposal role to be just the governor, so only governor can propose stuff to the timelock.
        timelock.grantRole(executorRole, address(0)); // can give this role to anybody, by setting it to "0" addr
        timelock.revokeRole(adminRole, USER); // remove admin from from USER, so USER will no longer be the admin.
        vm.stopPrank();

        box = new Box();
        box.transferOwnership(address(timelock)); // misconception is shouldn't we tranfer to the DAO? NO. we should transfer to the timelock
        // the Timelock Owns the DAO, and DAO owns the TimeLock. weird 2-way Relationship, but it's the timelock tt gets the ultimate say on where stuff goes. 
    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        box.store(1); // the owner is now the timelock(DAO)
        // so it should pass, because u can't update the box, unless it's through governance
    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 888;
        // we will then need to create a proposal
        // we will need the arguments of the function "propose()", in Governor.sol
        string memory description = "store 1 in box";
        bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)",valueToStore); // this is the calldata, to call the function store(), and store a value
        
        values.push(0); // we create a uint256[] values; on top as a global varable. then we push "0" value here.
        calldatas.push(encodedFunctionCall);
        targets.push(address(box));

        ////////////////////////
        // 1. Propose to the DAO
        uint256 proposalId = governor.propose(targets,values, calldatas, description);
        // View the state
        console.log("Proposal State: ", uint256(governor.state(proposalId))); // should return "0" which is pending. governor.state returns ProposalState (see IGovernor.sol's ProposalState{} )

        
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        //vm.warp(block.number + VOTING_DELAY + 1); // can update to ROLL.
        vm.roll(block.number + VOTING_DELAY + 1);
        // time pass...

        console.log("Proposal State: ", uint256(governor.state(proposalId))); // Now the state should be active.
    
        /////////////////////
        // 2. VOTE (now we can start coting on soemthing.)
        string memory reason = "This is my reason";
        // in order to vote, we need to call this .castVote() function. 
        // we look under the GovernorCountingSimple.sol's _countVote() u see voteType. ( 0=Against, 1=For, 2=Abstain)
        uint8 voteWay = 1; //voting yes
        vm.prank(USER);
        governor.castVoteWithReason(proposalId, voteWay, reason);
        
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        console.log("block.number: ",block.number);
        console.log("block.timestamp: ",block.timestamp);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        /////////////////////
        // 3. Queue the TX
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY + 1);

        console.log("block.number: ",block.number);
        console.log("block.timestamp: ",block.timestamp);

        /////////////////////
        // 4. execute
        governor.execute(targets, values, calldatas, descriptionHash);
        console.log("Box value: ", box.getNumber());

        assert(box.getNumber() == valueToStore);
    }
}