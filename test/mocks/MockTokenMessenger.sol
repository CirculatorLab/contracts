// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "../../src/interfaces/ITokenMessenger.sol";
import "./MockPermitERC20.sol";

contract MockTokenMessenger is ITokenMessenger {
    function depositForBurn(
        uint256 _amount,
        uint32, /*_destinationDomain*/
        bytes32, /*_mintRecipient*/
        address _burnToken
    ) external override returns (uint64 /*nonce*/ ) {
        // mimic the burn action for easier testing
        MockPermitERC20(_burnToken).burn(msg.sender, _amount);

        return 0;
    }
}
