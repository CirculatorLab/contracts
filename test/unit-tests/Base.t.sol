// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/Test.sol";
import "../../src/Circulator.sol";
import "../../src/CirculatorProxy.sol";
import "../mocks/MockPermitERC20.sol";
import "../mocks/MockTokenMessenger.sol";
import "../mocks/MockTokenMinter.sol";
import "../mocks/MockV3SpokePool.sol";

contract UnitTestBase is Test {
    Circulator circulator;

    // Mocked contracts
    MockPermitERC20 usdc;
    MockTokenMessenger tokenMessenger;
    MockTokenMinter tokenMinter;
    MockV3SpokePool v3SpokePool;

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
    uint256[] relayerFees = [uint256(1e6), uint256(0.1e6)];
    uint256[] minFees = [uint256(1e6), uint256(0.1e6)];
    uint256[] chainIds = [1, 2];
    address[] tokens = [makeAddr("chainA_USDC"), makeAddr("chainB_USDC")];

    function setUp() public {
        usdc = new MockPermitERC20("USDC", "USDC");
        tokens[0] = address(usdc);

        tokenMessenger = new MockTokenMessenger();
        tokenMinter = new MockTokenMinter();
        v3SpokePool = new MockV3SpokePool();

        address[] memory delegators = new address[](1);
        delegators[0] = delegator;

        // create implementation
        address implementation =
            address(new Circulator(address(usdc), address(tokenMessenger), address(tokenMinter), address(v3SpokePool)));

        // create proxy
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

        _setupDestinationConfigs();

        _setupMintLimit();

        _setBalances();
    }

    function _setupDestinationConfigs() internal {
        vm.prank(owner);
        circulator.initDestinationConfigs(domainIds, relayerFees, minFees, chainIds, tokens);
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

    function _expectRevertNonOwner(address _sender) internal {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _sender));
    }
}
