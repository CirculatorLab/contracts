// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {UnitTestBase} from "./Base.t.sol";
import {ICirculator} from "../../src/interfaces/ICirculator.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DestinationConfigTest is UnitTestBase {
    uint32 constant TEST_DOMAIN = 1;
    uint256 constant NEW_CHAIN_ID = 1337;
    address constant NEW_TOKEN_ADDRESS = address(0x1234567890123456789012345678901234567890);

    function test_setDestinationChainId() public {
        // Arrange
        uint256 initialChainId = circulator.getDestinationConfigs(TEST_DOMAIN).chainId;

        // Act
        vm.prank(owner);
        circulator.setDestinationChainId(TEST_DOMAIN, NEW_CHAIN_ID);

        // Assert
        ICirculator.DestinationCofigs memory config = circulator.getDestinationConfigs(TEST_DOMAIN);
        assertEq(config.chainId, NEW_CHAIN_ID);
        assertNotEq(config.chainId, initialChainId);
    }

    function test_RevertWhen_NonOwnerSetsDestinationChainId() public {
        // Act & Assert
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        circulator.setDestinationChainId(TEST_DOMAIN, NEW_CHAIN_ID);
    }

    function test_setDestinationToken() public {
        // Arrange
        address initialToken = circulator.getDestinationConfigs(TEST_DOMAIN).token;

        // Act
        vm.prank(owner);
        circulator.setDestinationToken(TEST_DOMAIN, NEW_TOKEN_ADDRESS);

        // Assert
        ICirculator.DestinationCofigs memory config = circulator.getDestinationConfigs(TEST_DOMAIN);
        assertEq(config.token, NEW_TOKEN_ADDRESS);
        assertNotEq(config.token, initialToken);
    }

    function test_RevertWhen_NonOwnerSetsDestinationToken() public {
        // Act & Assert
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        circulator.setDestinationToken(TEST_DOMAIN, NEW_TOKEN_ADDRESS);
    }

    function test_EmitEventWhen_SetDestinationChainId() public {
        // Arrange
        vm.prank(owner);

        // Act & Assert
        vm.expectEmit(true, true, false, true);
        emit ICirculator.DestinationChainIdUpdated(TEST_DOMAIN, NEW_CHAIN_ID);
        circulator.setDestinationChainId(TEST_DOMAIN, NEW_CHAIN_ID);
    }

    function test_EmitEventWhen_SetDestinationToken() public {
        // Arrange
        vm.prank(owner);

        // Act & Assert
        vm.expectEmit(true, true, false, true);
        emit ICirculator.DestinationTokenUpdated(TEST_DOMAIN, NEW_TOKEN_ADDRESS);
        circulator.setDestinationToken(TEST_DOMAIN, NEW_TOKEN_ADDRESS);
    }
}
