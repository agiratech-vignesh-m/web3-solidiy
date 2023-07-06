// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EventBriteCoin is ERC20, Ownable {
    
    constructor(uint _amount) ERC20("EventBriteCoin", "EVNT") {
        uint conversion = _amount * (10**18);
        _mint(msg.sender, conversion);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}