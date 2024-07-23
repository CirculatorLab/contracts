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

    /// @dev Revert when actual amount being teleported is less than minimum amount.
    error AmountLessThanMinimum();

    /// @dev Revert when signature is invalid.
    error InvalidDelegateSignature();

    /// @dev Struct for encapsulating data needed for circleAsset permit.
    /// @param sender Address of the sender.
    /// @param deadline Deadline for the permit.
    /// @param amount Amount to be circulated, including fee.
    /// @param v Signature v.
    /// @param r Signature r.
    /// @param s Signature s.
    struct PermitData {
        address sender;
        uint256 deadline;
        uint256 amount;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @dev Struct for encapsulating data needed for delegate circulate
    /// @param destinationDomain Destination domain ID.
    /// @param recipient Address of the recipient.
    /// @param v Signature v.
    /// @param r Signature r.
    /// @param s Signature s.
    struct DelegateData {
        uint32 destinationDomain;
        bytes32 recipient;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice Emitted when someone teleports tokens to another domain.
    /// @param sender Address of the sender.
    /// @param receiver Address of the receiver.
    /// @param destinationDomain Destination domain ID.
    /// @param amount Amount circulated
    /// @param fee Fee paid
    /// @param nonce Unique nonce for this token burn
    event Circulate(
        address indexed sender,
        bytes32 indexed receiver,
        uint32 indexed destinationDomain,
        uint256 amount,
        uint256 fee,
        uint64 nonce
    );

    /// @notice Emitted when a someone teleport tokens to another domain using permit.
    /// @param relayer Address of the relayer.
    /// @param sender Address of the sender.
    /// @param receiver Address of the receiver.
    /// @param destinationDomain Destination domain ID.
    /// @param amount Amount circulated
    /// @param fee Fee paid
    /// @param nonce Unique nonce for this token burn
    event DelegateCirculate(
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
    event DestinationMinFeeUpdated(uint32 indexed destinationDomain, uint256 fee);

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

    /**
     * @notice Circulate a specified amount to destination chain and emits a `Circulate` event.
     * @dev This function burns a token amount for the given recipient and destination domain.
     * @param _amount Amount to be circulated
     * @param _recipient The address of the recipient in bytes32 format.
     * @param _destinationDomain The ID of the destination domain.
     * @return _nonce Burn nonce for the teleport.
     */
    function circulate(uint256 _amount, bytes32 _recipient, uint32 _destinationDomain)
        external
        returns (uint64 _nonce);

    /**
     * @notice Teleport on behalf of a user with signatures.
     * @dev In the current version, only whitelisted delegator can call this function to circulate on behalf of other users.
     * @param permitData Data needed for the permit.
     * @param delegateData Data needed for the delegate.
     */
    function delegateCirculate(PermitData calldata permitData, DelegateData calldata delegateData)
        external
        returns (uint64 _nonce);

    /**
     * @notice Calculates the total fee for a given amount and destination domain.
     * @dev The function computes the service fee for the provided amount and adds the relayer fee
     * associated with the specified destination domain. The total fee is the greater of the sum
     * or the base fee associated with the destination domain.
     * @param _amount Amount for which the fee needs to be calculated.
     * @param _destinationDomain The domain ID for which relayer and base fees are fetched.
     * @return _finalFee The total fee denominated in circleAsset
     */
    function totalFee(uint256 _amount, uint32 _destinationDomain) external view returns (uint256 _finalFee);

    /**
     * @notice Calculates the service fee for a given amount.
     * @dev This function computes the service fee by multiplying the provided amount with the service fee percentage
     * @param _amount Amount for which the service fee needs to be calculated.
     * @return _fee Calculated service fee denominated in circleAsset
     */
    function getServiceFee(uint256 _amount) external view returns (uint256 _fee);

    /**
     * @notice Get the delegate fee in circleAsset when using delegateCirculate.
     * @return _fee Delegator fee denominated in circleAsset
     */
    function delegateFee() external view returns (uint256 _fee);
}
