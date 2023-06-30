// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
 
// just an example if u want to code out your own erc20 token, but recommended to just import.
contract ManualToken {
    mapping(address => uint256 ) private s_balances;

    // function name() public pure returns(string memory) {
    //     return "Manual Token";
    // }
    // can also be written like
    string public name = "Manual Token";

    function totalSupply() public pure returns(uint256) {
        return 100 ether;
    }

    function decimals() public pure returns(uint8) {
        return 18;
    }

    function balanceOf(address _owner) public view returns(uint256 balance) {
        return s_balances[_owner];
    }

    function transfer(address _to, uint _amount) public {
        uint256 previousBalances = balanceOf(msg.sender) + balanceOf(_to);
        s_balances[msg.sender] -= _amount;
        s_balances[_to] += _amount;
        require(balanceOf(msg.sender)+balanceOf(_to) == previousBalances);
    }

// etc +++ all the other required functions below

}