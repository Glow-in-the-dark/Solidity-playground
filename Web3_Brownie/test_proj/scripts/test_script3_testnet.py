### This example is for scripting on Mainnet/Testnet  ------
from brownie import Storage1 , accounts, config

def main(): 
    # Accessing the latest deployment instance
    contract_instance = Storage1[-1] 
    # If you have deployed multiple instances of the contract, you can access each of them separately by adjusting the index ([-1]).  

    # ---- (Method 1) If we load using the accounts, and not via the config file(brownie-config.yaml) ----
    # loading the stored account --- ( run [>> brownie accounts list ] to see what accounts are stored)
    # account = accounts.load(“Gavin_test”) 
    # ----------------------------------------------------------------------------------------------------

    # ---- (Method 2) if we lead the account directly using the private key --------------------
    # (Method 2) is kinda better because you will be asked to confirm your password everytime
    account = accounts.add(config["account-keys"] ["private-key"])
    # ------------------------------------------------------------------------------------------

    # storing a number
    transaction_receipt = contract_instance.store(15, {"from": account})
    # Wait for transaction confirmation
    print(transaction_receipt)
    # Retrieve the number
    retrieved_number = contract_instance.retrieve()
    # Print the retrieved number
    print(f"Number Retrieved: {retrieved_number}")