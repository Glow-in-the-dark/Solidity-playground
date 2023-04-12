// const ethers = require("ethers");
// const fs = require("fs-extra");
// require("dotenv").config();

import { ethers } from "ethers";
import * as fs from "fs-extra";
import "dotenv/config";

async function main() {
  // compile them in this code
  // or compile them separately.
  // http://127.0.0.1:8545 (ganache)
  // https://sepolia.infura.io/v3/ (sepolia testnet)

  // This is where we connect to different blockchain/ RPC.
  const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL!);
  // This gives us a wallet with a private key, to interact with the chain.
  // Method 1 ( Direct from .env ) ------------------
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);
  // ------------------------------------------------

  //   // Method 2 ( decrypt from encryptedKey.Json) -------------
  //   const encryptedJson = fs.readFileSync("./.encryptedKey.json", "utf8");
  //   let wallet = new ethers.Wallet.fromEncryptedJsonSync( //Decrypt to get private key.
  //     encryptedJson,
  //     process.env.PRIVATE_KEY_PASSWORD
  //   );
  //   wallet = await wallet.connect(provider); //wallet needs RPC details too
  //   // --------------------------------------------------------

  // In order to deploy, we need both the ABI and the Binary compile code. and to read these two files, we need to import the fs(filesystem) module. if don't have, just >> yarn add fs-extra
  const abi = fs.readFileSync("./SimpleStorage_sol_SimpleStorage.abi", "utf8");
  const binary = fs.readFileSync(
    "./SimpleStorage_sol_SimpleStorage.bin",
    "utf8"
  );

  const contractFactory = new ethers.ContractFactory(abi, binary, wallet);
  console.log("deploying, please wait...");

  // === Deploy with ethers.js here. (the USUAL way) ===
  const contract = await contractFactory.deploy(); // use AWAIT here to say, STOP here, wait for contract to deploy, before storing it into the variable.
  // const contract = await contractFactory.deploy({gasPrice: 100}) // you can define how u want to deploy, customize it.
  // const contract = await contractFactory.deploy({gasLimit: 1000000000})
  console.log("I Deployed This Contract:", contract);
  console.log(`Deployed Contract Address: ${contract.address}`);
  // === The usual way =========

  //   // ======= if you want to WAIT for a certain numer of blocks before confirming tx receipts.
  //   const txReceipt = await contract.deployed(1); //wait 1 block
  //   console.log("Here is the deployment transaction(Transaction response): ");
  //   console.log(contract.deployTransaction);
  //   // Transaction response, is just what u get when u create your tx.

  //   // Note: TxReciept and deployment transaction is DIFFERENT. ( you only get a txReciept, when u wait() for a block confirmation)
  //   console.log("This is the transaction receipt for 1 block.");
  //   console.log(txReceipt);

  //   // ======================================================================================================================
  //   // ===== NOW TO CUSTOMIZE and PACKAGE OUR OWN TRANSACTION, to DEPLOY via sending a transaction ===========
  //   // ======================================================================================================================
  //   //   const { chainId } = await provider.getNetwork();
  //   //   console.log(chainId); // check ChainID(networkID)

  //   console.log("Lets' deploy with only just TX data!!");
  //   const nonce = await wallet.getTransactionCount();
  //   console.log(nonce);
  //   const tx = {
  //     nonce: nonce,
  //     gasPrice: 20000000000,
  //     gasLimit: 1000000,
  //     to: null, // null cuz we creating a contract
  //     value: 0, // since we creating a contract, we not sending any money over.
  //     // data: add "0x" then <the binary data> of say the contract u wanna deploy.
  //     data: "0x608060405234801561001057600080fd5b50610780806100206000396000f3fe608060405234801561001057600080fd5b50600436106100575760003560e01c80632e64cec11461005c5780636057361d1461007a5780636f760f41146100965780639e7a13ad146100b2578063b2ac62ef146100e3575b600080fd5b610064610113565b6040516100719190610539565b60405180910390f35b610094600480360381019061008f919061047c565b61011c565b005b6100b060048036038101906100ab9190610420565b61012f565b005b6100cc60048036038101906100c7919061047c565b6101c5565b6040516100da929190610554565b60405180910390f35b6100fd60048036038101906100f891906103d7565b610281565b60405161010a9190610539565b60405180910390f35b60008054905090565b8060008190555061012b610113565b5050565b60006040518060400160405280838152602001848152509050600181908060018154018082558091505060019003906000526020600020906002020160009091909190915060008201518160000155602082015181600101908051906020019061019a9291906102af565b505050816002846040516101ae9190610522565b908152602001604051809103902081905550505050565b600181815481106101d557600080fd5b90600052602060002090600202016000915090508060000154908060010180546101fe9061064d565b80601f016020809104026020016040519081016040528092919081815260200182805461022a9061064d565b80156102775780601f1061024c57610100808354040283529160200191610277565b820191906000526020600020905b81548152906001019060200180831161025a57829003601f168201915b5050505050905082565b6002818051602081018201805184825260208301602085012081835280955050505050506000915090505481565b8280546102bb9061064d565b90600052602060002090601f0160209004810192826102dd5760008555610324565b82601f106102f657805160ff1916838001178555610324565b82800160010185558215610324579182015b82811115610323578251825591602001919060010190610308565b5b5090506103319190610335565b5090565b5b8082111561034e576000816000905550600101610336565b5090565b6000610365610360846105a9565b610584565b90508281526020810184848401111561038157610380610713565b5b61038c84828561060b565b509392505050565b600082601f8301126103a9576103a861070e565b5b81356103b9848260208601610352565b91505092915050565b6000813590506103d181610733565b92915050565b6000602082840312156103ed576103ec61071d565b5b600082013567ffffffffffffffff81111561040b5761040a610718565b5b61041784828501610394565b91505092915050565b600080604083850312156104375761043661071d565b5b600083013567ffffffffffffffff81111561045557610454610718565b5b61046185828601610394565b9250506020610472858286016103c2565b9150509250929050565b6000602082840312156104925761049161071d565b5b60006104a0848285016103c2565b91505092915050565b60006104b4826105da565b6104be81856105e5565b93506104ce81856020860161061a565b6104d781610722565b840191505092915050565b60006104ed826105da565b6104f781856105f6565b935061050781856020860161061a565b80840191505092915050565b61051c81610601565b82525050565b600061052e82846104e2565b915081905092915050565b600060208201905061054e6000830184610513565b92915050565b60006040820190506105696000830185610513565b818103602083015261057b81846104a9565b90509392505050565b600061058e61059f565b905061059a828261067f565b919050565b6000604051905090565b600067ffffffffffffffff8211156105c4576105c36106df565b5b6105cd82610722565b9050602081019050919050565b600081519050919050565b600082825260208201905092915050565b600081905092915050565b6000819050919050565b82818337600083830152505050565b60005b8381101561063857808201518184015260208101905061061d565b83811115610647576000848401525b50505050565b6000600282049050600182168061066557607f821691505b60208210811415610679576106786106b0565b5b50919050565b61068882610722565b810181811067ffffffffffffffff821117156106a7576106a66106df565b5b80604052505050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b600080fd5b600080fd5b600080fd5b600080fd5b6000601f19601f8301169050919050565b61073c81610601565b811461074757600080fd5b5056fea26469706673582212200e7159a28be547f2eace58352e534cd112107f4bda85c8b872be43adac638e0864736f6c63430008070033",
  //     chainId: 1337, // for example, for my ganache, my chain id is 1337
  //   };

  //   //   // However, this is a tx, with all these Info propagated, but it is not SIGNED yet.
  //   //   const signedTxResponse = await wallet.signTransaction(tx);
  //   //   console.log(signedTxResponse);
  //   //   // This however is s Signed transactin, but not a SENT signed transaction, therefore we change it to:
  //   const sentTxResponse = await wallet.sendTransaction(tx);
  //   await sentTxResponse.wait(1); // make sure it has 1 block confirmation first.
  //   console.log(sentTxResponse);
  //   // ===== CUSTOMIZED PERSONALIZED TX END ===================================================================================

  // ======================================
  // Interacting with contract with Ether.js
  // ======================================

  const currentFavouriteNumber = await contract.retrieve();
  console.log(currentFavouriteNumber);
  console.log(`Current Favourite Number: ${currentFavouriteNumber.toString()}`);

  const txResponse = await contract.store("7"); //when we call a function in a contract, we get a tx response.
  const transactionReciept = await txResponse.wait(1); // once we wait for it to finish, we get a receipt.
  const updatedFavNumber = await contract.retrieve();
  console.log(`updated favourite number is ${updatedFavNumber}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
