// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {UnitTestBase} from "./Base.t.sol";
import {ICirculator} from "../../src/interfaces/ICirculator.sol";

contract FeeTest is UnitTestBase {
    function test_ServiceFeeHigherOnChainA() public view {
        // Arrange
        uint256 amount = 10000e6;

        // Assert
        assertGt(
            circulator.totalFee(amount, chainADomain, ICirculator.CirculateType.Cctp),
            circulator.totalFee(amount, chainBDomain, ICirculator.CirculateType.Cctp)
        );
    }

    function test_CollectFee() public {
        // Arrange
        uint256 aliceBalanceBefore = usdc.balanceOf(alice);
        uint256 fee = 50e6;
        usdc.mint(address(circulator), fee);

        // Act
        vm.prank(feeRecipient);
        circulator.collectFee(address(usdc), alice);

        // Assert
        uint256 aliceBalanceAfter = usdc.balanceOf(alice);
        assertEq(aliceBalanceAfter, aliceBalanceBefore + fee);
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

    function test_RevertWhen_setEmptyFeeCollector() public {
        // Act
        vm.prank(owner);
        vm.expectRevert(ICirculator.ZeroAddress.selector);
        circulator.setFeeCollector(address(0));
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

    function test_setRelayFee() public {
        // Arrange
        uint256 newFee = 0.2e6;

        // Act
        vm.prank(owner);
        circulator.setDestinationRelayerFee(chainADomain, newFee);

        // Assert
        ICirculator.DestinationCofigs memory chainAConfig = circulator.getDestinationConfigs(chainADomain);
        assertEq(chainAConfig.relayerFee, newFee);
    }

    function test_setMinFee() public {
        // Arrange
        uint256 newFee = 0.25e6;

        // Act
        vm.prank(owner);
        circulator.setDestinationMinFee(chainADomain, newFee);

        // Assert
        ICirculator.DestinationCofigs memory chainAConfig = circulator.getDestinationConfigs(chainADomain);
        assertEq(chainAConfig.minFee, newFee);
    }
}
