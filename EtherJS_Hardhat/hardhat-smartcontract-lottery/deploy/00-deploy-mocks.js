const { network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");

// you need these two variables cuz, when we deploy the V2Mock contract, we need to input these 2 arguments, which will go into the contract's constructor.
const BASE_FEE = ethers.utils.parseEther("0.25"); // cost 0.25 link per request. Seen from: https://docs.chain.link/vrf/v2/subscription/supported-networks
const GAS_PRICE_LINK = 1e9; //calculated value based on the gas price of the chain. (link per Gas) so the keepers get compensated for GAS paid to run the contract on certain time.

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const args = [BASE_FEE, GAS_PRICE_LINK];

  if (developmentChains.includes(network.name)) {
    log("Local network detected! Deploying mocks");
    // deploy a mock vrfcoordinator..
    await deploy("VRFCoordinatorV2Mock", {
      from: deployer,
      log: true,
      args: args, // we can see from the github that the VRFCoordinatorV2Mock.sol contract's constructor take in 2 arguments.
    });
    log("Mocks Deployed!");
    log("------------------------------------------");
  }
};

module.exports.tags = ["all", "mocks"];
