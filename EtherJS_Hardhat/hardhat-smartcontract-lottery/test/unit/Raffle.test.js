const { assert, expect } = require("chai");
const { network, getNamedAccounts, deployments, ethers } = require("hardhat");
const {
  developmentChains,
  networkConfig,
} = require("../../helper-hardhat-config");

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("Raffle Unit Test", function () {
      // initiate global variables
      let raffle, vrfCoordinatorV2Mock, raffleEntranceFee, deployer, interval;
      chainId = network.config.chainId;

      beforeEach(async function () {
        // const { deployer } = await getNamedAccounts() // no need this, and use the line below, cuz we want to to be global var
        deployer = (await getNamedAccounts()).deployer;
        await deployments.fixture(["all"]);
        raffle = await ethers.getContract("Raffle", deployer);
        vrfCoordinatorV2Mock = await ethers.getContract(
          "VRFCoordinatorV2Mock",
          deployer
        );
        raffleEntranceFee = await raffle.getEntranceFee();
        interval = await raffle.getInterval();
      });

      describe("constructor", function () {
        it("initializes the raffle correctly", async function () {
          //Ideally we make our test have just 1 assert per "it"
          const raffleState = await raffle.getRaffleState(); // make sure the raffle starts in the "open" state so ppl can participate
          assert.equal(raffleState.toString(), "0"); // "0" because see line 26 of raffle.sol. OPEN state = 0, first state
          assert.equal(interval.toString(), networkConfig[chainId]["interval"]);
          // could have created more asserts to check the rest of the constructor, but since it's tutorial, we skip
        });
      });

      describe("enterRaffle", function () {
        // Check for errors/reverts
        it("reverts when you don't pay enough", async function () {
          await expect(raffle.enterRaffle()).to.be.revertedWith(
            "Raffle__NotEnoughETHEntered"
          );
        });
        // remember to check that it records player when they enter
        it("records player when they enter", async function () {
          await raffle.enterRaffle({ value: raffleEntranceFee });
          const playerFromContract = await raffle.getPlayer(0);
          assert.equal(playerFromContract, deployer);
        });
        // check that events are emit, syntax abit similar to checking for errors
        it("emits event on enter", async function () {
          await expect(
            raffle.enterRaffle({ value: raffleEntranceFee })
          ).to.emit(raffle, "RaffleEnter");
        });

        // Check for errors/reverts, BUT how do we get it to the "CALCULATING" state ??
        // performUpkeep() is the func which move the state from "OPEN" to "CALCULATING"
        // performUpkeep() will check that checkUpkeep() returns TRUE first, otherwise, revert with "Raffle__UpkeepNotNeeded"
        // So now we need to make it TRUE first, and we pretend we are the chainlink Network
        // And we need to PAss time SO..    >>> Time-travel(hardhat)  >> see hardhat network>reference in website for DOCs
        it("doesn't allow entrance when raffle is calculating", async function () {
          await expect(raffle.enterRaffle({ value: raffleEntranceFee }));
          await network.provider.send("evm_increaseTime", [
            interval.toNumber() + 1,
          ]);
          await network.provider.send("evm_mine", []); // we use [] empty array cause we just want to mine 1 empty block
          // await network.provider.request({ method: "evm_mine", params: [] }); // same as above, but top one more succinct
          // Since we enterRaffle, and it should be "isOpen", "timePassed", "hasPlayer", "hasBalance" all true,
          // Then now we can PRETEND to be a chainlink keeper, to call performUpkeep().
          await raffle.performUpkeep([]); // we pass an empty [], because it's an empty calldata.
          // NOW, this should be in a "CALCULATING" state.
          await expect(
            raffle.enterRaffle({ value: raffleEntranceFee })
          ).to.be.revertedWith("Raffle__NotOpen");
        });
      });
      describe("checkUpkeep", function () {
        it("returns false if people haven't sent any ETH", async function () {
          await network.provider.send("evm_increaseTime", [
            interval.toNumber() + 1,
          ]);
          await network.provider.send("evm_mine", []);
          // await raffle.performUpkeep([]); // this is a public function, and not a "public view", so there will be a transaction, which will cost gas
          // but you don't want to send a transaction, you want to simulate a tx to see what the "upkeepNeeded" will return.
          // so u use "callstatic"
          const { upkeepNeeded } = await raffle.callStatic.checkUpkeep([]);
          assert(!upkeepNeeded);
        });
        it("returns false if raffle isn't open", async function () {
          await raffle.enterRaffle({ value: raffleEntranceFee });
          await network.provider.send("evm_increaseTime", [
            interval.toNumber() + 1,
          ]);
          await network.provider.send("evm_mine", []);
          await raffle.performUpkeep("0x");
          const raffleState = await raffle.getRaffleState();
          const { upkeepNeeded } = await raffle.callStatic.checkUpkeep([]);
          assert.equal(raffleState.toString(), "1");
          assert.equal(upkeepNeeded, false);
        });
        it("returns false if enough time hasn't passed", async () => {
          await raffle.enterRaffle({ value: raffleEntranceFee });
          await network.provider.send("evm_increaseTime", [
            interval.toNumber() - 5,
          ]); // use a higher number here if this test fails
          await network.provider.request({ method: "evm_mine", params: [] });
          const { upkeepNeeded } = await raffle.callStatic.checkUpkeep("0x"); // upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers)
          assert(!upkeepNeeded);
        });
        it("returns true if enough time has passed, has players, eth, and is open", async () => {
          await raffle.enterRaffle({ value: raffleEntranceFee });
          await network.provider.send("evm_increaseTime", [
            interval.toNumber() + 1,
          ]);
          await network.provider.request({ method: "evm_mine", params: [] });
          const { upkeepNeeded } = await raffle.callStatic.checkUpkeep("0x"); // upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers)
          assert(upkeepNeeded);
        });
      });
      describe("performUpkeep", function () {
        it("can only run if checkupkeep is true", async () => {
          await raffle.enterRaffle({ value: raffleEntranceFee });
          await network.provider.send("evm_increaseTime", [
            interval.toNumber() + 1,
          ]);
          await network.provider.request({ method: "evm_mine", params: [] });
          const tx = await raffle.performUpkeep("0x");
          assert(tx);
        });
        it("reverts if checkup is false", async () => {
          await expect(raffle.performUpkeep("0x")).to.be.revertedWith(
            "Raffle__UpkeepNotNeeded"
          );
        });
        it("updates the raffle state and emits a requestId", async () => {
          // Too many asserts in this test!
          await raffle.enterRaffle({ value: raffleEntranceFee });
          await network.provider.send("evm_increaseTime", [
            interval.toNumber() + 1,
          ]);
          await network.provider.request({ method: "evm_mine", params: [] });
          const txResponse = await raffle.performUpkeep("0x"); // emits requestId
          const txReceipt = await txResponse.wait(1); // waits 1 block
          const raffleState = await raffle.getRaffleState(); // updates state
          const requestId = txReceipt.events[1].args.requestId; // [1], and not [0] because line 121, runs after line 113, which requestRandomWords, will first emit an event first.
          assert(requestId.toNumber() > 0);
          assert(raffleState == 1); // 0 = open, 1 = calculating
        });
      });

      describe("fulfillRandomWords", function () {
        // add a beforeEach, we want somebody to enter the raffle, before we run any test here.
        beforeEach(async () => {
          await raffle.enterRaffle({ value: raffleEntranceFee });
          await network.provider.send("evm_increaseTime", [
            interval.toNumber() + 1,
          ]);
          await network.provider.request({ method: "evm_mine", params: [] });
        });
        it("can only be called after performupkeep", async () => {
          await expect(
            vrfCoordinatorV2Mock.fulfillRandomWords(0, raffle.address) // reverts if not fulfilled
          ).to.be.revertedWith("nonexistent request");
          await expect(
            vrfCoordinatorV2Mock.fulfillRandomWords(1, raffle.address) // reverts if not fulfilled
          ).to.be.revertedWith("nonexistent request");
          // so use fuzzing rather than just 0,1,... and many other numbers
        });

        // This test is too big...
        // This test simulates users entering the raffle and wraps the entire functionality of the raffle
        // inside a promise that will resolve if everything is successful.
        // An event listener for the WinnerPicked is set up
        // Mocks of chainlink keepers and vrf coordinator are used to kickoff this winnerPicked event
        // All the assertions are done once the WinnerPicked event is fired
        it("picks a winner, resets, and sends money", async () => {
          const additionalEntrances = 3; // to test for the additional number of players joining
          const startingIndex = 2; //deployer = 0
          const accounts = await ethers.getSigners();
          for (
            let i = startingIndex;
            i < startingIndex + additionalEntrances;
            i++
          ) {
            // i = 2; i < 5; i=i+1
            const accountConnectedRaffle = raffle.connect(accounts[i]); // Returns a new instance of the Raffle contract connected to player
            await accountConnectedRaffle.enterRaffle({
              value: raffleEntranceFee,
            });
          }
          const startingTimeStamp = await raffle.getLatestTimeStamp(); // stores starting timestamp (before we fire our event)

          // we want to PerformUpkeep() (mock being chainlink keepers), which will kickoff ...
          // calling the  fulfillRandomWords () (mock being the Chainlink VRF)
          // then we check if everything in fulfillRandomWords() get reset, like the winner, the rafflestate, players[], timestamp....
          // if is live testnet, we need to wait for fulfillRandomWords to be called, but we are on hardhat, we can simulate it.
          // however, we need to simulate, waiting for it, so we need to set up a "listener", but we don't want this test to finish before the listener is done listening
          // therefore we need to create "PROMISE". Below --

          // This will be more important for our staging tests...
          await new Promise(async (resolve, reject) => {
            // event listener for WinnerPicked, once "winnerPicked" event gets emitted... do some stuff
            raffle.once("WinnerPicked", async () => {
              console.log("Found the event! 'WinnerPicked' event fired!");
              // assert throws an error if it fails, so we need to wrap
              // it in a try/catch so that the promise returns event
              // if it fails.
              try {
                // is it here which we check if the values are reset.
                const recentWinner = await raffle.getRecentWinner();
                const raffleState = await raffle.getRaffleState();
                const winnerBalance = await accounts[2].getBalance();
                const endingTimeStamp = await raffle.getLatestTimeStamp();
                await expect(raffle.getPlayer(0)).to.be.reverted;
                // Comparisons to check if our ending values are correct:
                assert.equal(recentWinner.toString(), accounts[2].address);
                assert.equal(raffleState, 0);
                assert.equal(
                  winnerBalance.toString(),
                  startingBalance // startingBalance + ( (raffleEntranceFee * additionalEntrances) + raffleEntranceFee )
                    .add(
                      raffleEntranceFee
                        .mul(additionalEntrances)
                        .add(raffleEntranceFee)
                    )
                    .toString()
                );
                assert(endingTimeStamp > startingTimeStamp);
                resolve(); // if try passes, resolves the promise
              } catch (e) {
                reject(e); // if try fails, rejects the promise
              }
            });

            // We Set up the "listener here" ... // for staging we won't need this part
            // kicking off the event by mocking the chainlink keepers and vrf coordinator
            const tx = await raffle.performUpkeep("0x");
            const txReceipt = await tx.wait(1);
            const startingBalance = await accounts[2].getBalance();
            await vrfCoordinatorV2Mock.fulfillRandomWords(
              txReceipt.events[1].args.requestId,
              raffle.address
            );
          });
        });
      });
    });
