// async function deployFunc(hre) {
//   console.log("hi!");
// }

// module.exports.default = deployFunc;

const {
  networkConfig,
  developmentChains,
} = require("../helper-hardhat-config.js");
const { network } = require("hardhat");
const { verify } = require("../utils/verify");
require("dotenv").config();

module.exports = async (hre) => {
  const { getNamedAccounts, deployments } = hre; // hre.getNamedAccounts & hre.deployments (deconstruction)
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts(); // This means grab the deployer from the "namedAccounts" that we named it at "hardhat.config.js"
  const chainId = network.config.chainId;

  // if chainId is X, use address Y
  // if chainId is Z use address A
  // we use helper-hardhat-config.js to help us with this.
  //   const ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"];
  let ethUsdPriceFeedAddress;
  if (developmentChains.includes(network.name)) {
    const ethUsdAggregator = await deployments.get("MockV3Aggregator");
    ethUsdPriceFeedAddress = ethUsdAggregator.address;
  } else {
    ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"];
  }

  // Mocking
  // if contract doesn't exit, we deploy a minimal version of it for our local testing.

  // what happens when we want to change chains ?
  // when going for localhost or hardhat network we want to use a mock.
  const args = [ethUsdPriceFeedAddress];
  //                             v -- Name of Contract we want to deploy(in string), { a list of overrides}
  const fundMe = await deploy("FundMe", {
    from: deployer,
    args: args, // pass the arguements to the Contract's constructor, in this case, (put price feed address)
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    //verify contract on etherscan
    await verify(fundMe.address, args);
  }
  log("----------------------------------------");
};

module.exports.tags = ["all", "fundme"];
