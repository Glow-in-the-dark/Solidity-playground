const { network } = require("hardhat");
const {
  developmentChains,
  DECIMALS,
  INITAL_ANSWER,
} = require("../helper-hardhat-config.js");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts(); // This means grab the deployer from the "namedAccounts" that we named it at "hardhat.config.js"

  if (developmentChains.includes(network.name)) {
    log("local network detected! deploying mocks...");
    await deploy("MockV3Aggregator", {
      contract: "MockV3Aggregator",
      from: deployer,
      log: true,
      args: [DECIMALS, INITAL_ANSWER], // check the MockV3aggregator for it's constructor, to see what we need to fill in.
    });
    log("Mocks deployed!");
    log("----------------------------------------");
  }
};

module.exports.tags = ["all", "mocks"];
