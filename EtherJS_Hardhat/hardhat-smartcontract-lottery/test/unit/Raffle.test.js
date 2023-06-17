const { assert, expect } = require("chai");
const { network, getNamedAccounts, deployments, ethers } = require("hardhat");
const {
  developmentChains,
  networkConfig,
} = require("../../helper-hardhat-config");

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("Raffle Unit Test", async function () {
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

      describe("constructor", async function () {
        it("initializes the raffle correctly", async function () {
          //Ideally we make our test have just 1 assert per "it"
          const raffleState = await raffle.getRaffleState(); // make sure the raffle starts in the "open" state so ppl can participate
          assert.equal(raffleState.toString(), "0"); // "0" because see line 26 of raffle.sol. OPEN state = 0, first state
          assert.equal(interval.toString(), networkConfig[chainId]["interval"]);
          // could have created more asserts to check the rest of the constructor, but since it's tutorial, we skip
        });
      });

      describe("enterRaffle", async function () {
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
    });
