from brownie import Storage1, accounts

# Note: While writing the test case functions, make sure you add the word “test” at the beginning of the function name. 
# While running the tests, Brownie will ignore the functions that do not have the “test” prefix. 

# To run test: 
# Open a terminal in your project directory and type:  >>>> brownie test 

def test_default_value():
    # fetch the account
    account = accounts[0]    
    # deploy contract
    deploy_contract = Storage1.deploy({"from":account})
    #retrieve default number
    retrieved_number = deploy_contract.retrieve()
    expected_result = 0
    assert retrieved_number == expected_result

def test_stored_value():
    # fetch the account
    account = accounts[0]
    # deploy contract
    deploy_contract = Storage1.deploy({"from":account})
    # store a number
    transaction_receipt = deploy_contract.store(1,{"from":account})
    transaction_receipt.wait(1)
    #retrieve number
    retrieved_number = deploy_contract.retrieve()
    expected_result = 1
    assert retrieved_number == expected_result