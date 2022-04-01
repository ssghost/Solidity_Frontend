
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DappToken is ERC20 {
    constructor() public ERC20("Shit Token", "SHIT"){
        _mint(msg.sender, 10 ** 18);
    }
}