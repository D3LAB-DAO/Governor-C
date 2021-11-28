// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20VotesComp.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Example is ERC20VotesComp, Ownable {
    constructor() ERC20("ERC-20 Example", "E2E") ERC20Permit("ERC-20 Example") {}
    
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}
