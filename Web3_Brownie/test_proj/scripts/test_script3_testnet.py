### This example is for scripting on Mainnet/Testnet  ------
from brownie import Storage1 , accounts 

def main(): 
    # Accessing the latest deployment instance
    # the [-1] after the "storage1" stands dor the 
    contract_instance = Storage1[-1]
    print(contract_instance)
    print(Storage1)


    # loading the stored account --- ( run [>> brownie accounts list ] to see what accounts are stored)
    account = accounts.load("Gavin_test")
    # storing a number
    transaction_receipt = contract_instance.store(15, {"from": account})
    # Wait for transaction confirmation
    print(transaction_receipt)
    # Retrieve the number
    retrieved_number = contract_instance.retrieve()
    # Print the retrieved number
    print(f"Number Retrieved: {retrieved_number}")