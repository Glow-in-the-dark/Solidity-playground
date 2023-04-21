const { getNamedAccounts, ethers, network } = require("hardhat");
const { developmentChains } = require("../../helper-hardhat-config");
const { assert } = require("chai");

developmentChains.includes(network.name) // wrap this whole test, so that if it's not on testnet, it will not run.
  ? describe.skip
  : describe("FundMe", async function () {
      let fundMe;
      let deployer;
      const sendValue = ethers.utils.parseEther("1");
      beforeEach(async function () {
        deployer = (await getNamedAccounts()).deployer;
        // No need Fixtures, contracts already deployed on testnet.
        fundMe = await ethers.getContract("FundMe", deployer); //get the most recent deployed contract of "FundMe"
        //Don't need mock, because for staging, we are assuming we are on testnet.
      });

      it("allows people to fund and withdraw", async function () {
        await fundMe.fund({ value: sendValue });
        await fundMe.withdraw();
        const endingBalance = await fundMe.provider.getBalance(fundMe.address);
      });
      assert.equal(endingBalance.toString(), "0");
    });

//// Run deploy, to deploy contract to testnet first
// yarn hardhat deploy --network sepolia
//// Then run:
// yarn hardhat test --network sepolia
//// and you will realise it only runs this test, which only consist of this "FundMe" test
