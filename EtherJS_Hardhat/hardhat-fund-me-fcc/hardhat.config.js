require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("dotenv").config();

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const USER1_PK = process.env.USER1_PK;
const CMC_API_KEY = process.env.CMC_API_KEY;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  //solidity: "0.8.8",
  solidity: {
    compilers: [{ version: "0.8.8" }, { version: "0.6.6" }],
  },
  defaultNetwork: "hardhat",
  networks: {
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: [PRIVATE_KEY, USER1_PK],
      chainId: 11155111,
      blockConfirmations: 6,
    },
    // This localhost network is different fron the default hardhat network. (it's a separate one)
    // This is the network, when u run "npx hardhat node", and when u run your script, on --network localhost, u can see the transactions.
    localhost: {
      url: "http://127.0.0.1:8545/",
      // accoutns already auto set and given by hardhat
      chainId: 31337,
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
    outputFile: "gas-report.txt",
    noColors: true,
    // coinmarketcap: COINMARKETCAP_API_KEY,
  },
  namedAccounts: {
    deployer: {
      default: 0, // the accounts[0] index will be deployer
      //11155111: 1, // This means for ChainId of (Sepolia), accounts[1] will be the deployer instead.
      //31337: 2 // means for hardhat, account[2] will be the deployer.
    },
    user: {
      default: 1, // the accounts[1] index will be user.
    },
  },
};
