#!/usr/bin/python3

from brownie import Token, accounts, config


def main():

    # Use the default which is this, for directly testing on ganache:  ---------
    # return Token.deploy("Test Token", "TST", 18, 1e21, {'from': accounts[0]})
    # --------------------------------------------------------------------------

    #### Use these for mainnet/testnet:
    # my_account = accounts.load('Gavin_test') # get from >> brownie account list, else add it in.  # This is with password validation at console.
    my_account = accounts.add(config["account-keys"] ["private-key"]) # use this, without having to login individually at console.

    deploy_contract = Token.deploy("Gav Test Token", "GAV", 18, 1e21,{"from":my_account})
    print(f"contract deployed at {deploy_contract}")