const { deployments, ethers } = require("hardhat");
const { assert, expect } = require("chai");

describe("FundMe", async function () {
  let fundMe;
  let deployer;
  let mockV3Aggregator;
  //deploy FundMe conctract first before we test.
  // using Hardhat-deploy
  beforeEach(async function () {
    // const accounts = await ethers.getSigners(); // this line will return the "accounts: [Private_key]" of your network.
    // const accountZero = accounts[0];
    deployer = (await getNamedAccounts()).deployer;
    await deployments.fixture(["all"]);
    (fundMe = await ethers.getContract("FundMe")), deployer; //get the most recent deployed contract of "FundMe"
    mockV3Aggregator = await ethers.getContract("MockV3Aggregator", deployer);
  });

  describe("constructor", async function () {
    //describe
    it("sets the aggregator address correctly", async function () {
      const response = await fundMe.priceFeed();
      assert.equal(response, mockV3Aggregator.address);
    });
  });

  describe("fund", async function () {
    it("Fails if you don't send enough ETH", async function () {
      await expect(fundMe.fund()).to.be.revertedWith(
        "you neeed to spend more ETH!"
      );
    });
  });
});
