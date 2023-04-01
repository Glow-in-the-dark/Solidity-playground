#!/usr/bin/python3
from brownie import Token, accounts, config

def main():
    gav_wallet = '0xC881B26DE56FAF8A008d7a5563CCfdD0b68b1965'
    last_GAV_ERC20 = Token[-1]      # will give the ADDRESS of the LAST DEPLOYED contract, and store it in the variable.

    # This will check how much an ADDRESS holds the specific ERC20 token of the deployed contract
    balanceTokens = last_GAV_ERC20.balanceOf(gav_wallet)
    Readable_balance_tokens = balanceTokens / 1e18
    print(f"{gav_wallet} has {Readable_balance_tokens}GAV")

    # Transfering erc20 tokens 
    Rinkerby_Mumbai_Test = '0x17cEE6B4F28D74cc33F5b7b756F6647b20e3F87d'
    # Note: we need to add the accounts here with "private-key", and cannot just simply use "gav_wallet" address, because we need it to sign transactions, in order to TRANSFER
    Gav_account = accounts.add(config["account-keys"] ["private-key"]) 

    amt_to_send = 2 * 1e18
    last_GAV_ERC20.transfer(Rinkerby_Mumbai_Test,amt_to_send, {'from': Gav_account})

    sender_balance = last_GAV_ERC20.balanceOf(gav_wallet) / 1e18
    receiver_balance = last_GAV_ERC20.balanceOf(Rinkerby_Mumbai_Test) / 1e18
    print(f"{Gav_account} has {sender_balance}GAV")
    print(f"{Rinkerby_Mumbai_Test} has {receiver_balance}GAV")


    