const { run } = require("hardhat");

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

module.exports = { verify };
