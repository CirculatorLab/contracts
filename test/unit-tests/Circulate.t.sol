// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {UnitTestBase, console2} from "./Base.t.sol";
import {ICirculator} from "../../src/interfaces/ICirculator.sol";
import {Pausable} from "@openzeppelin/utils/Pausable.sol";

contract CirculateTest is UnitTestBase {
    function test_Circulate() public {
        // Arrange
        uint256 amount = 1000e6;
        uint256 aliceBalanceBefore = usdc.balanceOf(alice);
        uint256 expectedFee = circulator.totalFee(amount, chainADomain, ICirculator.CirculateType.Cctp);

        // Act
        vm.startPrank(alice);
        usdc.approve(address(circulator), amount);
        uint256 fee = circulator.totalFee(amount, chainADomain, ICirculator.CirculateType.Cctp);
        circulator.circulate(
            amount, amount - fee, alice, chainADomain, uint32(block.timestamp), ICirculator.CirculateType.Cctp
        );
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
        circulator.circulate(
            amount, amount - 1, alice, chainADomain, uint32(block.timestamp), ICirculator.CirculateType.Cctp
        );
        vm.stopPrank();
    }

    function test_RevertWhen_Paused() public {
        // Arrange
        uint256 amount = 1000e6;

        // Act & Asset
        vm.prank(owner);
        circulator.pause();

        uint256 fee = circulator.totalFee(amount, chainADomain, ICirculator.CirculateType.Cctp);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        circulator.circulate(
            amount, amount - fee, alice, chainADomain, uint32(block.timestamp), ICirculator.CirculateType.Cctp
        );
        vm.stopPrank();
    }
}
