from web3 import Web3 
#this part to load .env file. ---
import os 
from dotenv import load_dotenv
load_dotenv()
## if you want to specify path to find .env file
# from pathlib import Path
# dotenv_path = Path('path/to/.env')
# load_dotenv(dotenv_path=dotenv_path)
# --------------------------------
from web3.middleware import geth_poa_middleware


# There are other providers like WebSocket and IPC providers
API_URL = os.getenv('API_URL')
w3 = Web3(Web3.HTTPProvider(API_URL))

print(w3.isConnected())

# How to get this ABI? This is obtained when you want to deploy the contract using Storage1.abi, usually also you can get this 
# from the explorer if the contract creator has uploaded the ABI to 
abi = [
    {
        'inputs': [],
        'name': "retrieve",
        'outputs': [
            {
                'internalType': "uint256",
                'name': "",
                'type': "uint256"
            }
        ],
        'stateMutability': "view",
        'type': "function"
    },
    {
        'inputs': [
            {
                'internalType': "uint256",
                'name': "num",
                'type': "uint256"
            }
        ],
        'name': "store",
        'outputs': [],
        'stateMutability': "nonpayable",
        'type': "function"
    }
]

contract = w3.eth.contract(address='0xC66FfC96265f41b5eC193eebeC611BFA517813Ff',abi=abi)
print(contract.functions.retrieve().call())

caller = "0xC881B26DE56FAF8A008d7a5563CCfdD0b68b1965"
PRIVATE_KEY = os.getenv('PRIVATE_KEY')
private_key = PRIVATE_KEY
nonce = w3.eth.getTransactionCount(caller)
cid = w3.eth.chain_id
print("nonce:"+str(nonce))
print("chainID:"+str(cid))

w3.middleware_onion.inject(geth_poa_middleware, layer=0) # this part is to prevent 
call_function = contract.functions.store(5).buildTransaction({"chainId": cid, "from": caller, "nonce": nonce})
print(call_function)
new_nonce = w3.eth.getTransactionCount(caller)
signed_tx = w3.eth.account.sign_transaction(call_function, private_key=PRIVATE_KEY)
send_tx= w3.eth.send_raw_transaction(signed_tx.rawTransaction)
new_nonce2 = w3.eth.getTransactionCount(caller)
print("new_nonce2:"+str(new_nonce2))

tx_receipt = w3.eth.wait_for_transaction_receipt(send_tx)
print(tx_receipt)
new_nonce3 = w3.eth.getTransactionCount(caller)
print("new_nonce3:"+str(new_nonce3))