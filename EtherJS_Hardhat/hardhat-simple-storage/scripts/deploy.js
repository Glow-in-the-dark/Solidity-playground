const { ethers, run, network } = require("hardhat");
// use the "run" to run hardhat commands, example verify, rather than doing it manually on the cmd prompt.
require("dotenv").config();

async function main() {
  const SimpleStorageFactory = await ethers.getContractFactory("SimpleStorage");
  console.log("Deploying contract");
  const simpleStorage = await SimpleStorageFactory.deploy();
  await simpleStorage.deployed();
  console.log(`Deployed contract address at: ${simpleStorage.address}`);

  // we only want to RUN the verify func() only if it is on a testnet, and not if it is on Localhost hardhat/ganache testnet.
  // So check if it is on the sepolia network, && if we have the etherscan API key, before we VERIFY.
  if (network.config.chainId === 11155111 && process.env.ETHERSCAN_API_KEY) {
    const wait_blocks = 3;
    console.log(`Waiting for ${wait_blocks} block txs...`);
    await simpleStorage.deployTransaction.wait(wait_blocks);
    await verify(simpleStorage.address, []);
  }

  const currentValue = await simpleStorage.retrieve();
  console.log(`Current Value is: ${currentValue}`);

  //Update the current value
  const transactionResponse = await simpleStorage.store(8);
  await transactionResponse.wait(1);
  const updatedValue = await simpleStorage.retrieve();
  console.log(`updated value is: ${updatedValue}`);
}

// verify on etherscan
// since this contract does not use constructors, we can skip out the "args"
async function verify(contractAddress, args) {
  console.log("verifying contract...");

  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    });
  } catch (error) {
    if (error.message.toLowerCase().includes("already verified")) {
      console.log("Already Verified!");
    } else {
      console.log(error);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
