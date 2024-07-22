// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {UnitTestBase} from "./Base.t.sol";
import {ICirculator} from "../../src/interfaces/ICirculator.sol";

contract DepositTest is UnitTestBase {
    function test_Deposit() public {
        // Arrange
        uint256 amount = 1000e6;
        uint256 aliceBalanceBefore = usdc.balanceOf(alice);
        uint256 expectedFee = circulator.totalFee(amount, chainADomain);

        // Act
        vm.startPrank(alice);
        usdc.approve(address(circulator), amount);
        circulator.deposit(amount, _toBytes32(alice), chainADomain);
        vm.stopPrank();

        // Assert
        uint256 aliceBalanceAfter = usdc.balanceOf(alice);
        assertEq(aliceBalanceAfter, aliceBalanceBefore - amount);

        uint256 circulatorBalance = usdc.balanceOf(address(circulator));
        assertEq(circulatorBalance, expectedFee);
    }

    function test_RevertWhen_AmountToLow() public {
        // Arrange
        uint256 amount = 1e6;

        // Act & Asset
        vm.startPrank(alice);
        usdc.approve(address(circulator), amount);
        vm.expectRevert(ICirculator.FeeNotCovered.selector);
        circulator.deposit(amount, _toBytes32(alice), chainADomain);
        vm.stopPrank();
    }
}
