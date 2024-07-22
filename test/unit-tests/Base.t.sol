// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../src/Circulator.sol";
import "../mocks/MockPermitERC20.sol";
import "../mocks/MockTokenMessenger.sol";
import "../mocks/MockTokenMinter.sol";

contract UnitTestBase is Test {
    Circulator circulator;

    // Mocked contracts
    MockPermitERC20 usdc;
    MockTokenMessenger tokenMessenger;
    MockTokenMinter tokenMinter;

    // Actors
    uint256 alicePk = uint256(0xaaaa);
    uint256 bobPk = uint256(0xbbbb);
    uint256 carolPk = uint256(0xcccc);

    address alice = vm.addr(alicePk);
    address bob = vm.addr(bobPk);
    address carol = vm.addr(carolPk);

    address feeRecipient = address(0xffeeee);
    address owner = address(0x123456);

    address delegator = address(0xddeeaa);

    // configs
    uint256 public delegateFee = 0.1e6;
    uint256 public serviceFeeBPS = 10;

    uint32 public chainADomain = 1;
    uint32 public chainBDomain = 2;

    uint32[] domainIds = [chainADomain, chainBDomain];
    uint256[] relayerFeeMaps = [uint256(1e6), uint256(0.1e6)];
    uint256[] baseFeeMaps = [uint256(1e6), uint256(0.1e6)];

    function setUp() public {
        usdc = new MockPermitERC20("USDC", "USDC");

        tokenMessenger = new MockTokenMessenger();
        tokenMinter = new MockTokenMinter();

        address[] memory delegators = new address[](1);
        delegators[0] = delegator;

        circulator = new Circulator(
            address(usdc),
            address(tokenMessenger),
            address(tokenMinter),
            owner,
            feeRecipient,
            delegators,
            delegateFee,
            serviceFeeBPS,
            domainIds,
            relayerFeeMaps,
            baseFeeMaps
        );

        _setupMintLimit();

        _setBalances();
    }

    function _setupMintLimit() internal {
        tokenMinter.setBurnLimit(address(usdc), 1_000_000e6);
    }

    function _setBalances() internal {
        usdc.mint(alice, 1_000_000e6);
        usdc.mint(bob, 1_000_000e6);
        usdc.mint(carol, 1_000_000e6);
    }

    function _toBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
