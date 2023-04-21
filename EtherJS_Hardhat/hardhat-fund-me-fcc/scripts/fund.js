const { getNamedAccounts, ethers } = require("hardhat");

async function main() {
  const { deployer } = await getNamedAccounts();
  const fundMe = await ethers.getContract("FundMe", deployer);
  console.log("Funding Contract...");
  const transactionResponse = await fundMe.fund({
    value: ethers.utils.parseEther("0.1"),
  });
  await transactionResponse.wait(1);

  console.log("Funded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// run:
/* 
  yarn hardhat node 
  // keep that terminal, and open another separate terminal, and run:
  yarn hardhat run scripts/fund.js --network localhost
  // check back on the previous terminal, and u get to see it is running properly, txs went through.
  */
