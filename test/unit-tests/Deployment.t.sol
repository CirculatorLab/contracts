// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {UnitTestBase} from "./Base.t.sol";
import {Circulator} from "../../src/Circulator.sol";
import {CirculatorProxy} from "../../src/CirculatorProxy.sol";

contract DeploymentTest is UnitTestBase {
    function test_DeploymentSetup() public {
        // Arrange
        address[] memory delegators = new address[](1);
        delegators[0] = delegator;

        address implementation =
            address(new Circulator(address(usdc), address(tokenMessenger), address(tokenMinter), address(v3SpokePool)));

        circulator = Circulator(
            address(
                new CirculatorProxy(
                    implementation,
                    abi.encodeWithSelector(
                        Circulator.initialize.selector, owner, feeRecipient, delegateFee, serviceFeeBPS, delegators
                    )
                )
            )
        );

        // assert
        assertEq(circulator.owner(), owner);
        assertEq(circulator.feeCollector(), feeRecipient);
        assertEq(circulator.delegateFee(), delegateFee);
        assertEq(circulator.serviceFeeBPS(), serviceFeeBPS);
        assertEq(circulator.delegators(delegator), true);
    }
}
