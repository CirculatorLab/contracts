// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {UnitTestBase} from "./Base.t.sol";

contract FeeTest is UnitTestBase {
    function test_ServiceFeeHigherOnChainA() public view {
        // Arrange
        uint256 amount = 10000e6;

        // Assert
        assertGt(circulator.totalFee(amount, chainADomain), circulator.totalFee(amount, chainBDomain));
    }

    function test_setDelegateFee() public {
        // Arrange
        uint256 newFee = 0.2e6;

        // Act
        vm.prank(owner);
        circulator.setDelegateFee(newFee);

        // Assert
        assertEq(circulator.delegateFee(), newFee);
    }

    function test_setServiceFee() public {
        // Arrange
        uint256 newFee = 20;

        // Act
        vm.prank(owner);
        circulator.setServiceFee(newFee);

        // Assert
        assertEq(circulator.serviceFeeBPS(), newFee);
    }

    function test_setFeeCollector() public {
        // Arrange
        address newFeeCollector = address(alice);

        // Act
        vm.prank(owner);
        circulator.setFeeCollector(newFeeCollector);

        // Assert
        assertEq(circulator.feeCollector(), newFeeCollector);
    }
}
