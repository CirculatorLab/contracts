// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {UnitTestBase} from "./Base.t.sol";

contract DelegatorTest is UnitTestBase {
    function test_CanSetDelegator() public {
        // Arrange
        address[] memory delegators = new address[](1);
        delegators[0] = alice;

        // Action
        vm.prank(owner);
        circulator.setDelegators(delegators, true);

        // Assert
        assertEq(circulator.delegators(alice), true);
    }

    function test_CanRemoveDelegator() public {
        // Arrange
        address[] memory delegators = new address[](1);
        delegators[0] = delegator;

        // Action
        vm.prank(owner);
        circulator.setDelegators(delegators, false);

        // Assert
        assertEq(circulator.delegators(delegator), false);
    }

    function test_RevertWhen_CallerNotOwner() public {
        // Arrange
        address[] memory delegators = new address[](1);
        delegators[0] = alice;

        // Act & Assert
        vm.startPrank(alice);
        _expectRevertNonOwner(alice);
        circulator.setDelegators(delegators, true);
    }
}
