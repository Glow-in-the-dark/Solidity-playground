const { getNamedAccounts, ethers } = require("hardhat");

async function main() {
  const { deployer } = await getNamedAccounts();
  const fundMe = await ethers.getContract("FundMe", deployer);
  console.log("Funding Contract...");
  const transactionResponse = await fundMe.withdraw();
  await transactionResponse.wait(1);

  console.log("Funds Withdrawn, Got it Back");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// run:
/*  
  // provided u also run " yarn hardhat node" on the other terminal, and have it loaded up and funded.
  yarn hardhat run scripts/withdraw.js --network localhost
  // check back on the previous terminal, and u get to see it is running properly, txs went through.
  */
