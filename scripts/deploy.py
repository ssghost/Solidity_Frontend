from brownie import accounts, config, network, interface, ShitToken, TokenFarm, LinkToken, MockV3Aggregator, MockWETH, MockDAI, Contract
from web3 import Web3
import yaml
import json
import os
import shutil

def deploy_contracts():
    account = get_account()
    shit_token = ShitToken.deploy({'from': account})
    token_farm = TokenFarm.deploy(shit_token.address, {'from': account}, publish_source=config["networks"][network.show_active()]["verify"])
    Txn = shit_token.transfer(token_farm.address, shit_token.totalSupply() - Web3.toWei(100, 'ether'), {'from': account})
    Txn.wait(1)
    weth_token = get_contract('weth_token')
    fau_token = get_contract('fau_token')
    dict_of_allowed_tokens = {
        shit_token: get_contract('dai_usd_price_feed'),
        fau_token: get_contract('dai_usd_price_feed'),
        weth_token: get_contract('eth_usd_price_feed'),
    }
    add_allowed(token_farm, dict_of_allowed_tokens, account)
    update_frontend()
    return token_farm, shit_token

def deploy_mocks(decimals=18, initial_value=2*10**18):
    account = get_account()
    LinkToken.deploy({'from': account})
    MockV3Aggregator.deploy(decimals, initial_value, {"from": account})
    MockDAI.deploy({'from': account})
    MockWETH.deploy({"from": account})

def get_account(index=None, id=None):
    if index:
        return accounts[index]
    if network.show_active() in ['development', 'ganache-local']:
        return accounts[0]
    if id:
        return accounts.load(id)
    return accounts.add(config["wallets"]["from_key"])

contract2mock = {
    "eth_usd_price_feed": MockV3Aggregator,
    "dai_usd_price_feed": MockV3Aggregator,
    "fau_token": MockDAI,
    "weth_token": MockWETH,
}

def get_contract(c_name):
    c_type = contract2mock[c_name]
    if network.show_active() in ['development', 'ganache-local']:
        if len(c_type) <= 0:
            deploy_mocks()
        contract = c_type[-1]
    else:
        try:
            c_address = config["networks"][network.show_active()][c_name]
            contract = Contract.from_abi(c_type._name, c_address, c_type.abi)
        except: KeyError
    return contract

def add_allowed(token_farm, allowed_dict, account):
    for token in allowed_dict:
        add_Txn = token_farm.addAllowedTokens(token.address, {'from': account})
        add_Txn.wait(1)
        set_Txn = token_farm.setPriceFeed(token.address, allowed_dict[token], {'from': account})
        set_Txn.wait(1)
    return token_farm

def link_payment(c_address, account=None, link_token=None, amount=10**18):
    account = account if account else get_account()
    link_token = link_token if link_token else get_contract("link_token")
    payment = interface.LinkTokenInterface(link_token).transfer(c_address, amount, {'from': account})
    return payment

def get_verify_status():
    verify = (
        config["networks"][network.show_active()]["verify"]
        if config["networks"][network.show_active()].get("verify")
        else False
    )
    return verify

def update_frontend():
    copy_folders("./build", "./frontend/src/chain-info")
    with open("brownie-config.yaml", 'r') as brownie_config:
        config_dict = yaml.load(brownie_config, Loader=yaml.FullLoader)
        with open("./frontend/src/brownie-config.json", 'w') as brownie_config_json:
            json.dump(config_dict, brownie_config_json)

def copy_folders(src, dest):
    if os.path.exists(dest):
        shutil.rmtree(dest)
    shutil.copytree(src, dest)

def issue_tokens():
    account = get_account()
    token_farm = get_contract("TokenFarm")
    issued = token_farm.issueTokens({'from': account})
    issued.wait(1)

def main():
    deploy_contracts()