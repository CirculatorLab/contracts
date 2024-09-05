// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ICirculator {
    // Errors
    /// @dev Revert when fee is greater than amount being circulated.
    error FeeNotCovered();

    /// @dev Revert when burn amount is less than output amount.
    error InsufficientInputAmount();

    /// @dev Revert when burn amount exceeds limit set by Circle TokenMinter.
    error BurnAmountExceedsLimit();

    /// @dev Revert when the caller is not a delegator.
    error NotDelegator();

    /// @dev Revert when actual amount being circulated is less than minimum amount.
    error AmountLessThanMinimum();

    /// @dev Revert when signature is invalid.
    error InvalidDelegateSignature();

    /// @dev Revert when the destination configs is invalid.
    error InvalidConfig();

    /// @dev Revert when the address is zero.
    error ZeroAddress();

    // Structs & Enums
    /// @dev Enum for circulate type.
    enum CirculateType {
        Cctp,
        Across
    }

    /// @dev Struct for encapsulating destination configurations.
    /// @param relayerFee Relayer fee for the destination.
    /// @param minFee Minimum fee for the destination.
    /// @param chainId Chain ID for the destination.
    /// @param token Token address for the destination.
    struct DestinationCofigs {
        uint256 relayerFee;
        uint256 minFee;
        uint256 chainId;
        address token;
    }

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
    /// @param fillDeadline Deadline for the filler to fill the transaction.
    /// @param circulateType Circulate type: Cctp or Across.
    /// @param recipient Address of the recipient.
    /// @param outputAmount Amount to be received by the recipient.å
    /// @param v Signature v.
    /// @param r Signature r.
    /// @param s Signature s.
    struct DelegateData {
        uint32 destinationDomain;
        uint32 fillDeadline;
        CirculateType circulateType;
        address recipient;
        uint256 outputAmount;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice Emitted when a someone circulate tokens to another domain using permit.
    /// @param delegator Address of the relayer.
    /// @param sender Address of the sender.
    /// @param receiver Address of the receiver.
    /// @param destinationDomain Destination domain ID.
    /// @param amount Amount circulated
    /// @param fee Fee paid
    /// @param nonce Unique nonce for this token burn
    event Circulate(
        address indexed sender,
        address indexed receiver,
        uint32 indexed destinationDomain,
        uint256 amount,
        uint256 fee,
        uint64 nonce,
        address delegator,
        CirculateType circulateType
    );

    /// @notice Emitted when the relayer fee for a destination is updated.
    /// @param destinationDomain Destination domain ID.
    /// @param fee New relayer fee.
    event DestinationRelayerFeeUpdated(uint32 indexed destinationDomain, uint256 fee);

    /// @notice Emitted when the base fee for a destination is updated.
    /// @param destinationDomain Destination domain ID.
    /// @param fee New base fee.
    event DestinationMinFeeUpdated(uint32 indexed destinationDomain, uint256 fee);

    /// @notice Emitted when the chain ID for a destination is updated.
    /// @param destinationDomain Destination domain ID.
    /// @param chainId New chain ID.
    event DestinationChainIdUpdated(uint32 indexed destinationDomain, uint256 chainId);

    /// @notice Emitted when the token for a destination is updated.
    /// @param destinationDomain Destination domain ID.
    /// @param token New token address.
    event DestinationTokenUpdated(uint32 indexed destinationDomain, address token);

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

    event FeeCollectorUpdated(address indexed feeCollector);

    /**
     * @notice Circulate a specified amount to destination chain and emits a `Circulate` event.
     * @dev This function burns a token amount for the given recipient and destination domain.
     * @param _inputAmount Amount to be circulated.
     * @param _outputAmount Amount to be received by the recipient.
     * @param _recipient The address of the recipient in bytes32 format.
     * @param _destinationDomain The ID of the destination domain.
     * @param _fillDeadline Deadline for the filler to fill the transaction.
     * @param _type Circulate type: Cctp or Across.
     * @return _nonce Burn nonce for the circulate.
     */
    function circulate(
        uint256 _inputAmount,
        uint256 _outputAmount,
        address _recipient,
        uint32 _destinationDomain,
        uint32 _fillDeadline,
        CirculateType _type
    ) external returns (uint64 _nonce);

    /**
     * @notice Circulate on behalf of a user with signatures.
     * @dev In the current version, only whitelisted delegator can call this function to circulate on behalf of other users.
     * @param _permitData Data needed for the permit.
     * @param _delegateData Data needed for the delegate.
     * @return _nonce Burn nonce for the circulate.
     */
    function delegateCirculate(PermitData calldata _permitData, DelegateData calldata _delegateData)
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
    function totalFee(uint256 _amount, uint32 _destinationDomain, CirculateType _type)
        external
        view
        returns (uint256 _finalFee);

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
