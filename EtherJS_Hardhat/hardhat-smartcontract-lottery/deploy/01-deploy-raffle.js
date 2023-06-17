const { network } = require("hardhat");
//const { ethers } = require("hardhat");
const {
  networkConfig,
  developmentChains,
} = require("../helper-hardhat-config");
const { verify } = require("../helper-hardhat-config");

const VRF_SUB_FUND_AMOUNT = ethers.utils.parseEther("2");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;
  let vrfCoordinatorV2Address, subscriptionId;

  if (developmentChains.includes(network.name)) {
    const vrfCoordinatorV2Mock = await ethers.getContract(
      "VRFCoordinatorV2Mock"
    );
    vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address;
    /* create a subscriptionId via Mock contract, on local Hardhat network. */
    const transactionResponse = await vrfCoordinatorV2Mock.createSubscription();
    const transactionReceipt = await transactionResponse.wait(1); //In this Reciept is where we can get the "subscriptionId"
    subscriptionId = transactionReceipt.events[0].args.subId; // Since it will emit the s_currentSubId, we can get from the events.
    // Fund the subscription (usually u'll need the LINK token on the real network to fund it)
    // But for this mock, we don't need to send LINK, can just set an amount.
    //// console.log to check on details.
    //console.log(transactionResponse);
    //console.log("print transactionReceipt:", transactionReceipt);

    await vrfCoordinatorV2Mock.fundSubscription(
      subscriptionId,
      VRF_SUB_FUND_AMOUNT
    );
  } else {
    // else if it is live Testnet's network instead,
    vrfCoordinatorV2Address = networkConfig[chainId]["vrfCoordinatorV2"];
    subscriptionId = networkConfig[chainId]["subscriptionId"]; // In this case, we hardcoded it because we use the website UIUX to get it, but we can automate it like above too.
  }

  const entranceFee = networkConfig[chainId]["entranceFee"];
  const gasLane = networkConfig[chainId]["gasLane"];
  const callbackGasLimit = networkConfig[chainId]["callbackGasLimit"];
  const interval = networkConfig[chainId]["interval"];
  const args = [
    vrfCoordinatorV2Address,
    entranceFee,
    gasLane,
    subscriptionId,
    callbackGasLimit,
    interval,
  ];
  const raffle = await deploy("Raffle", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  // Check if it is on a localhost devchain && have a etherscan_api_key, and if it is not, verify it on etherscan.
  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    log("Verifying...");
    await verify(raffle.address, args);
  }
  log("---------------------------------------");
};

module.exports.tags = ["all", "raffle"];
