// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ICirculator {
    // Errors

    /// @dev Revert when fee is greater than amount being circulated.
    error FeeNotCovered();

    /// @dev Revert when burn amount exceeds limit set by Circle TokenMinter.
    error BurnAmountExceedsLimit();

    /// @dev Revert when the caller is not a delegator.
    error NotDelegator();

    /// @dev Revert when actual amount being bridged is less than minimum amount.
    error AmountLessThanMinimum();

    /// @dev Revert when signature is invalid.
    error InvalidDelegateSignature();

    /// @dev Struct for encapsulating data needed for deposit with permit.
    struct PermitData {
        address sender;
        uint256 deadline;
        uint256 amount;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct DelegateData {
        uint32 destinationDomain;
        bytes32 recipient;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice Emitted when a deposit is made.
    /// @param sender Address of the sender.
    /// @param receiver Address of the receiver.
    /// @param destinationDomain Destination domain ID.
    /// @param amount Amount deposited.
    /// @param fee Fee taken for this deposit.
    /// @param nonce Unique nonce for this deposit.
    event Deposited(
        address indexed sender,
        bytes32 indexed receiver,
        uint32 indexed destinationDomain,
        uint256 amount,
        uint256 fee,
        uint64 nonce
    );

    /// @notice Emitted when a deposit is made with a permit.
    /// @param relayer Address of the relayer.
    /// @param sender Address of the sender.
    /// @param receiver Address of the receiver.
    /// @param destinationDomain Destination domain ID.
    /// @param amount Amount deposited.
    /// @param fee Fee taken for this deposit with permit.
    /// @param nonce Unique nonce for this burn
    event PermitDeposited(
        address indexed relayer,
        address indexed sender,
        bytes32 receiver,
        uint32 indexed destinationDomain,
        uint256 amount,
        uint256 fee,
        uint64 nonce
    );

    /// @notice Emitted when the relayer fee for a destination is updated.
    /// @param destinationDomain Destination domain ID.
    /// @param fee New relayer fee.
    event DestinationRelayerFeeUpdated(uint32 indexed destinationDomain, uint256 fee);

    /// @notice Emitted when the base fee for a destination is updated.
    /// @param destinationDomain Destination domain ID.
    /// @param fee New base fee.
    event DestinationBaseFeeUpdated(uint32 indexed destinationDomain, uint256 fee);

    /// @notice Emitted when the delegate fee is updated.
    /// @param fee New delegate fee.
    event DelegateFeeUpdated(uint256 fee);

    /// @notice Emitted when service fee is updated.
    /// @param feeBPS New service fee in BPS.
    event ServiceFeeUpdated(uint256 feeBPS);

    /// @notice Emitted when a delegator's status is updated.
    /// @param delegator Address of the delegator.
    /// @param status Enabled as delegator or disabled.
    event DelegatorUpdated(address indexed delegator, bool status);
}
