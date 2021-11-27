// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20VotesComp.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * References
 */
contract DAPPO is ERC20VotesComp, Ownable {
    constructor() ERC20("DAO for DAPP", "DAPPO") ERC20Permit("DAPPO") {}
    
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    // TODO: capped
}
