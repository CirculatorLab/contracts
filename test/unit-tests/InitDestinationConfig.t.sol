// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {UnitTestBase} from "./Base.t.sol";
import {ICirculator} from "../../src/interfaces/ICirculator.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Initializable} from "@openzeppelin/proxy/utils/Initializable.sol";
import {Circulator} from "../../src/Circulator.sol";

contract InitDestinationConfigTest is UnitTestBase {
    function test_DestinationConfigsAreCorrectlyInitialized() public view {
        for (uint256 i = 0; i < domainIds.length; i++) {
            ICirculator.DestinationCofigs memory config = circulator.getDestinationConfigs(domainIds[i]);
            assertEq(config.relayerFee, relayerFees[i]);
            assertEq(config.minFee, minFees[i]);
            assertEq(config.chainId, chainIds[i]);
            assertEq(config.token, tokens[i]);
        }
    }

    function test_RevertWhen_InitializingTwice() public {
        // Arrange
        uint32[] memory newDomainIds = new uint32[](1);
        newDomainIds[0] = 3;

        uint256[] memory newRelayerFees = new uint256[](1);
        newRelayerFees[0] = 0.3e6;

        uint256[] memory newMinFees = new uint256[](1);
        newMinFees[0] = 0.15e6;

        uint256[] memory newChainIds = new uint256[](1);
        newChainIds[0] = 3;

        address[] memory newTokens = new address[](1);
        newTokens[0] = address(0x3333333333333333333333333333333333333333);

        // Act & Assert
        vm.prank(owner);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        circulator.initDestinationConfigs(newDomainIds, newRelayerFees, newMinFees, newChainIds, newTokens);
    }

    function test_RevertWhen_NonOwnerInitializesConfigs() public {
        // Arrange
        uint32[] memory newDomainIds = new uint32[](1);
        newDomainIds[0] = 3;

        uint256[] memory newRelayerFees = new uint256[](1);
        newRelayerFees[0] = 0.3e6;

        uint256[] memory newMinFees = new uint256[](1);
        newMinFees[0] = 0.15e6;

        uint256[] memory newChainIds = new uint256[](1);
        newChainIds[0] = 3;

        address[] memory newTokens = new address[](1);
        newTokens[0] = address(0x3333333333333333333333333333333333333333);

        // Act & Assert
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        circulator.initDestinationConfigs(newDomainIds, newRelayerFees, newMinFees, newChainIds, newTokens);
    }
}