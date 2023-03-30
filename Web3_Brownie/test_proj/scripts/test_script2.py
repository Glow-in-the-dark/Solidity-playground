from brownie import Storage1 , accounts 

def main(): 
    # Fetch the account 
    account = accounts[0] 
    # Deploy contract 
    deploy_contract = Storage1.deploy({"from":account}) 
    # Print contract address 
    print(f"contract deployed at {deploy_contract}")

# Accessing one of the accounts (provided by Ganache CLI) using the accounts object.
# Calling the deploy function of the contractContainer object 
# Passing the account as a parameter to the deploy function.
# Returning the ProjectContract of the contract to the deploy_contract variable.

### To RUN the SCRIPT
# open terminal in project folder, which brownie is installed and type:
# brownie run deploy_interact.py #or <any_other_name>.py

# use .call() to read,
# use send method to invoke functions that alter the state of the chain.

    # ----- Store ------
    # Store a number, by calling the "store" function in Storage1 smart contract
    transaction_receipt = deploy_contract.store(15, {"from":account}) 
    # Wait for transaction confirmation 
    transaction_receipt.wait(1) #you can change this number, (1) means we wait for 1 new block to be mined before we confirm the tx finality

    # ---- READ ----
    retrieved_number = deploy_contract.retrieve.call() 
    #or 
    retrieved_number1 = deploy_contract.retrieve()

    print(f"Number Retrieved : {retrieved_number}")
    print(f"Number Retrieved1 : {retrieved_number1}")