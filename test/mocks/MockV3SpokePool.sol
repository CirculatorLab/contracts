// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/interfaces/IV3SpokePool.sol";
import "./MockPermitERC20.sol";

contract MockV3SpokePool is IV3SpokePool {
    function depositV3(
        address _depositor,
        address, /*_recipient*/
        address _inputToken,
        address, /*_outputToken*/
        uint256 _inputAmount,
        uint256, /*_outputAmount*/
        uint256, /*_destinationChainId*/
        address, /*_exclusiveRelayer*/
        uint32, /*_quoteTimestamp*/
        uint32, /*_fillDeadline*/
        uint32, /*_exclusivityPeriod*/
        bytes calldata /*_message*/
    ) public payable {
        // mimic the transferFrom action for easier testing
        MockPermitERC20(_inputToken).transferFrom(_depositor, address(this), _inputAmount);
    }

    function numberOfDeposits() external pure returns (uint32) {
        return 0;
    }
}
