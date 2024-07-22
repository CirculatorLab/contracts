// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {UnitTestBase} from "./Base.t.sol";
import {ICirculator} from "../../src/interfaces/ICirculator.sol";

import {MessageHashUtils} from "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract PermitDepositTest is UnitTestBase {
    // common variables
    uint256 amount = 1000e6;
    uint256 deadline = block.timestamp + 1000;

    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    function test_PermitDeposit() public {
        uint256 aliceBalanceBefore = usdc.balanceOf(alice);

        // Sign Permit
        (uint8 v, bytes32 r, bytes32 s) = _signPermit(alicePk, block.timestamp + 1000, amount);
        ICirculator.PermitData memory permitData = ICirculator.PermitData(alice, deadline, amount, v, r, s);
        // Sign Delegate
        (v, r, s) = _signDelegate(alicePk, chainADomain, _toBytes32(bob));
        ICirculator.DelegateData memory delegateData = ICirculator.DelegateData(chainADomain, _toBytes32(bob), v, r, s);

        // Act
        vm.startPrank(delegator);
        circulator.permitDeposit(permitData, delegateData);
        vm.stopPrank();

        // Assert
        uint256 aliceBalanceAfter = usdc.balanceOf(alice);
        assertEq(aliceBalanceAfter, aliceBalanceBefore - amount);
    }

    function test_RevertWhen_DelegateDataChanged() public {
        // Arrange

        // Sign Permit
        (uint8 v, bytes32 r, bytes32 s) = _signPermit(alicePk, deadline, amount);
        ICirculator.PermitData memory permitData = ICirculator.PermitData(alice, deadline, amount, v, r, s);
        // Sign Delegate
        (v, r, s) = _signDelegate(alicePk, chainADomain, _toBytes32(bob));
        ICirculator.DelegateData memory delegateData = ICirculator.DelegateData(chainADomain, _toBytes32(bob), v, r, s);

        // Maliciously change the delegateData
        delegateData.recipient = _toBytes32(delegator);

        // Act & Assert
        vm.startPrank(delegator);
        vm.expectRevert(ICirculator.InvalidDelegateSignature.selector);
        circulator.permitDeposit(permitData, delegateData);
        vm.stopPrank();
    }

    function test_RevertWhen_SigReused() public {
        // Send the 1st legal transaction
        (uint8 v, bytes32 r, bytes32 s) = _signPermit(alicePk, deadline, amount);
        ICirculator.PermitData memory permitData = ICirculator.PermitData(alice, deadline, amount, v, r, s);
        (v, r, s) = _signDelegate(alicePk, chainADomain, _toBytes32(bob));
        ICirculator.DelegateData memory delegateData = ICirculator.DelegateData(chainADomain, _toBytes32(bob), v, r, s);
        vm.startPrank(delegator);
        circulator.permitDeposit(permitData, delegateData);

        // Only re-sign the permit signature, leave the delegate signature the same
        (v, r, s) = _signPermit(alicePk, deadline, amount);
        permitData = ICirculator.PermitData(alice, deadline, amount, v, r, s);

        // Act & Assert
        vm.expectRevert(ICirculator.InvalidDelegateSignature.selector);
        circulator.permitDeposit(permitData, delegateData);

        vm.stopPrank();
    }

    function _signPermit(uint256 pk, uint256 _deadline, uint256 _amount)
        internal
        view
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        uint256 nonce = usdc.nonces(vm.addr(pk));
        bytes32 hashedStruct =
            keccak256(abi.encode(PERMIT_TYPEHASH, vm.addr(pk), address(circulator), _amount, nonce, _deadline));

        bytes32 domainSeparator = usdc.DOMAIN_SEPARATOR();

        bytes32 eip712Hash = MessageHashUtils.toTypedDataHash(domainSeparator, hashedStruct);
        (v, r, s) = vm.sign(pk, eip712Hash);
    }

    function _signDelegate(uint256 pk, uint32 destDomain, bytes32 recipient)
        internal
        view
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        uint256 nonce = circulator.nonces(vm.addr(pk));
        return _signDelegateWithNonce(pk, nonce, destDomain, recipient);
    }

    function _signDelegateWithNonce(uint256 pk, uint256 nonce, uint32 destDomain, bytes32 recipient)
        internal
        view
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        bytes32 typeHash = circulator.DELEGATE_DEPOSIT_TYPEHASH();
        bytes32 hashedStruct = keccak256(abi.encode(typeHash, destDomain, recipient, nonce));

        bytes32 domainSeparator = circulator.DOMAIN_SEPARATOR();
        bytes32 eip712Hash = MessageHashUtils.toTypedDataHash(domainSeparator, hashedStruct);

        (v, r, s) = vm.sign(pk, eip712Hash);
    }
}
