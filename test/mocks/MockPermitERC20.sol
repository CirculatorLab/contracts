// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockPermitERC20 is ERC20Permit {
    constructor(string memory _name, string memory _symbol) ERC20Permit(_name) ERC20(_name, _symbol) {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}
