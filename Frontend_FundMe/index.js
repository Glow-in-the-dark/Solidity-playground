import { ethers } from "./ethers-5.2.esm.min.js";
import { abi, contractAddress } from "./constants.js";

const connectButton = document.getElementById("connectButton");
const balanceButton = document.getElementById("balanceButton");
const fundButton = document.getElementById("fundButton");
const withdrawButton = document.getElementById("withdrawButton");
connectButton.onclick = connect;
fundButton.onclick = fund;
balanceButton.onclick = getBalance;
withdrawButton.onclick = withdraw;

async function connect() {
  if (typeof window.ethereum !== "undefined") {
    //console.log("I see metamask...connecting...");
    await window.ethereum.request({ method: "eth_requestAccounts" }); //pop up metamask to connect, so now our website can now make API to metamask
    console.log("connected!");
    connectButton.innerHTML = " Connected!";
  } else {
    //console.log("no Metamask Detected.");
    connectButton.innerHTML = " Please Install Metamask!";
  }
}

async function getBalance() {
  if (typeof window.ethereum !== "undefined") {
    const provider = new ethers.providers.Web3Provider(window.ethereum); //check the RPC endpoint u are using, then puts it here.
    const balance = await provider.getBalance(contractAddress);
    console.log(ethers.utils.formatEther(balance));
  }
}

async function fund(ethAmount) {
  ethAmount = document.getElementById("ethAmount").value;
  console.log(`Funding with ${ethAmount}...`);
  if (typeof window.ethereum !== "undefined") {
    //// to send a tx, we always need
    // provider (connection to the chain)
    // signer / wallet ( someone with some gas)
    // contract that we are interacting with
    // ^ ABI & ADDRESS of contract
    const provider = new ethers.providers.Web3Provider(window.ethereum); //check the RPC endpoint u are using, then puts it here.
    const signer = provider.getSigner(); // return whichever wallet it is currently connect to
    const contract = new ethers.Contract(contractAddress, abi, signer);
    console.log(provider);
    console.log(signer);
    console.log(contract);
    try {
      const transactionResponse = await contract.fund({
        value: ethers.utils.parseEther(ethAmount),
      });
      //// hey, wait for this tx to finish
      // use "await" , so it will stop there until it is completely done.
      await listenForTransactionMine(transactionResponse, provider);
      console.log("Done!");
      // listen for the tx to be mined
      // listen for an event < -- haven't learn yet.;
    } catch (error) {
      console.log(error);
    }
  }
}

//purposely not async
function listenForTransactionMine(transactionResponse, provider) {
  console.log(`mining ${transactionResponse.hash}...`);
  // listen for this transaction to finish
  // we wrap the check for transaction reciept inside the promise, else reason see this: https://youtu.be/gyMwXuJrbJQ?t=48370
  return new Promise((resolve, reject) => {
    provider.once(transactionResponse.hash, (transactionReceipt) => {
      console.log(
        `Completed with ${transactionReceipt.confirmations} confirmations`
      );
      resolve(); // the promise will only resolve, once it fired this event.
    });
  });
  // /// Create a listener for the blockchain
}

async function withdraw() {
  if (typeof window.ethereum !== "undefined") {
    console.log("withdrawing...");
    const provider = new ethers.providers.Web3Provider(window.ethereum); //check the RPC endpoint u are using, then puts it here.
    const signer = provider.getSigner(); // return whichever wallet it is currently connect to
    const contract = new ethers.Contract(contractAddress, abi, signer);
    try {
      const transactionResponse = await contract.withdraw();
      await listenForTransactionMine(transactionResponse, provider);
    } catch (error) {
      console.log(error);
    }
  }
}
