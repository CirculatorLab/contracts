// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// Interfaces
import {IERC20Permit} from "@openzeppelin/token/ERC20/extensions/IERC20Permit.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {ITokenMessenger} from "./interfaces/ITokenMessenger.sol";
import {ITokenMinter} from "./interfaces/ITokenMinter.sol";
import {ICirculator} from "./interfaces/ICirculator.sol";

// Inherited contracts
import {Pausable} from "@openzeppelin/utils/Pausable.sol";
import {Nonces} from "@openzeppelin/utils/Nonces.sol";
import {EIP712} from "@openzeppelin/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/utils/cryptography/ECDSA.sol";

import {FeeOperator} from "./FeeOperator.sol";

// Libraries
import {SafeERC20} from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

/// @author CirculatorLabs
contract Circulator is ICirculator, FeeOperator, Pausable, EIP712, Nonces {
    using SafeERC20 for IERC20;

    bytes32 public constant DELEGATE_DEPOSIT_TYPEHASH =
        keccak256("DelegateDeposit(uint32 destinationDomain,bytes32 recipient,uint256 nonce)");

    ///@dev asset to be circulated.
    address public immutable circleAsset;

    ///@dev Reference to the Circle Bridge contract/interface.
    ITokenMessenger public immutable tokenMessenger;

    ///@dev Reference to the local minter interface.
    ITokenMinter public immutable localMinter;

    ///@dev Fee for delegators. denominated in circleAsset
    uint256 public delegateFee;

    ///@dev Service fee in BPS
    uint256 public serviceFeeBPS;

    ///@dev Mapping of destination domain to relayer fee.
    mapping(uint32 destinationDomain => uint256 fee) public relayerFeeMaps;

    ///@dev Mapping of destination domain to base fee.
    mapping(uint32 destinationDomain => uint256 fee) public baseFeeMaps;

    ///@dev Mapping of authorized delegators
    mapping(address delegator => bool) public delegators;

    /**
     * @notice Initializes the contract with provided parameters.
     * @dev Constructor to set up initial configurations of the bridge contract.
     * @param _tokenMessenger Address of the tokenMessenger contract.
     * @param _localMinter Address of the local minter contract.
     * @param _feeCollector Address of the fee collector.
     * @param _delegators List of initial delegator addresses to be set.
     * @param _delegateFee Fixed fee for the source chain.
     * @param _serviceFeeBPS Percentage of the service fee (for the source chain).
     * @param _domainIds List of domain IDs.
     * @param _relayerFeeMaps List of relayer fees corresponding to each domain ID.
     * @param _baseFeeMaps List of base fees corresponding to each domain ID.
     */
    constructor(
        address _circleAsset,
        address _tokenMessenger,
        address _localMinter,
        address _initialOwner,
        address _feeCollector,
        address[] memory _delegators,
        uint256 _delegateFee,
        uint256 _serviceFeeBPS,
        uint32[] memory _domainIds,
        uint256[] memory _relayerFeeMaps,
        uint256[] memory _baseFeeMaps
    ) FeeOperator(_initialOwner, _feeCollector) EIP712("Circulator", "v1") {
        circleAsset = _circleAsset;

        tokenMessenger = ITokenMessenger(_tokenMessenger);

        IERC20(_circleAsset).approve(_tokenMessenger, type(uint256).max);

        localMinter = ITokenMinter(_localMinter);
        // Set approved delegators
        for (uint256 i = 0; i < _delegators.length; i++) {
            delegators[_delegators[i]] = true;
        }
        // Set base fee and relayer fees
        for (uint256 i = 0; i < _domainIds.length; i++) {
            relayerFeeMaps[_domainIds[i]] = _relayerFeeMaps[i];
            baseFeeMaps[_domainIds[i]] = _baseFeeMaps[i];
        }
        // Source chain fixed fee
        delegateFee = _delegateFee;
        // Service fee in BPS
        serviceFeeBPS = _serviceFeeBPS;
    }

    /**
     * @notice Modifier to ensure that a given burn amount for a token doesn't exceed the allowed burn limit.
     * @dev Queries the `burnLimitsPerMessage` from the `localMinter` to get the maximum allowed burn amount for the token.
     * @param amount The amount of the token being requested to burn.
     */
    modifier onlyWithinBurnLimit(uint256 amount) {
        uint256 _allowedBurnAmount = localMinter.burnLimitsPerMessage(circleAsset);
        if (amount > _allowedBurnAmount) revert BurnAmountExceedsLimit();
        _;
    }

    /**
     * @notice Deposits a specified amount to the bridge and emits a `Deposited` event.
     * @dev This function burns a token amount for the given recipient and destination domain.
     * @param _amount Amount to be deposited.
     * @param _recipient The address of the recipient in bytes32 format.
     * @param _destinationDomain The ID of the destination domain.
     * @return _nonce A unique identifier for this deposit.
     */
    function deposit(uint256 _amount, bytes32 _recipient, uint32 _destinationDomain)
        external
        whenNotPaused
        onlyWithinBurnLimit(_amount)
        returns (uint64 _nonce)
    {
        // Calculate regular deposit fee
        uint256 fee = totalFee(_amount, _destinationDomain);
        // Check if fee is covered
        if (fee > _amount) revert FeeNotCovered();
        // Transfer tokens to be burned to this contract
        IERC20(circleAsset).safeTransferFrom(msg.sender, address(this), _amount);
        // Deposit tokens to the bridge
        _nonce = tokenMessenger.depositForBurn(_amount - fee, _destinationDomain, _recipient, circleAsset);
        // Emit an event
        emit Deposited(msg.sender, _recipient, _destinationDomain, _amount, fee, _nonce);
    }

    /**
     * @notice Deposits on behalf of a user using a permit (off-chain signature).
     * @dev Only a registered delegator can call this function to deposit on behalf of a user.
     * @param permitData Data needed for the permit.
     * @param delegateData Data needed for the delegate.
     */
    function permitDeposit(PermitData calldata permitData, DelegateData calldata delegateData)
        external
        whenNotPaused
        onlyWithinBurnLimit(permitData.amount)
    {
        if (!delegators[msg.sender]) revert NotDelegator();

        // Calculate delegate mode deposit fee
        uint256 fee = totalFee(permitData.amount, delegateData.destinationDomain) + delegateFee;
        if (fee > permitData.amount) revert FeeNotCovered();

        // Permit and fetch asset
        IERC20Permit(circleAsset).permit(
            permitData.sender,
            address(this),
            permitData.amount,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );
        IERC20(circleAsset).safeTransferFrom(permitData.sender, address(this), permitData.amount);

        // Get amount to be bridged
        uint256 bridgeAmt = permitData.amount - fee;

        // Verify the delegate data and signature
        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATE_DEPOSIT_TYPEHASH,
                delegateData.destinationDomain,
                delegateData.recipient,
                _useNonce(permitData.sender)
            )
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, delegateData.v, delegateData.r, delegateData.s);
        if (signer != permitData.sender) {
            revert InvalidDelegateSignature();
        }

        // Bridge the tokens
        uint64 burnNonce = tokenMessenger.depositForBurn(
            bridgeAmt, delegateData.destinationDomain, delegateData.recipient, circleAsset
        );

        // Emit an event
        emit PermitDeposited(
            msg.sender, // The relayer address
            permitData.sender, // The user address that signed the permit
            delegateData.recipient, // The recipient address
            delegateData.destinationDomain, // The destination domain ID
            bridgeAmt, // The amount bridged
            fee, // The fee taken for Circulator
            burnNonce // The nonce for this deposit
        );
    }

    /**
     * @notice Calculates the total fee for a given amount and destination domain.
     * @dev The function computes the service fee for the provided amount and adds the relayer fee
     * associated with the specified destination domain. The total fee is the greater of the sum
     * or the base fee associated with the destination domain.
     * @param _amount Amount for which the fee needs to be calculated.
     * @param _destinationDomain The domain ID for which relayer and base fees are fetched.
     * @return _finalFee The total fee denominated in circleAsset
     */
    function totalFee(uint256 _amount, uint32 _destinationDomain) public view returns (uint256 _finalFee) {
        uint256 _txFee = getServiceFee(_amount) + relayerFeeMaps[_destinationDomain];
        _finalFee = _max(_txFee, baseFeeMaps[_destinationDomain]);
    }

    /**
     * @notice Calculates the service fee for a given amount.
     * @dev This function computes the service fee by multiplying the provided amount with the service fee percentage
     * and dividing by the fee denominator.
     * @param _amount Amount for which the service fee needs to be calculated.
     * @return _fee Calculated service fee denominated in circleAsset
     */
    function getServiceFee(uint256 _amount) public view returns (uint256 _fee) {
        _fee = (_amount * serviceFeeBPS) / 1e4;
    }

    /**
     * @notice Sets the relayer fee for a specific destination domain.
     * @dev Only callable by the contract owner.
     * @param _destinationDomain The domain ID for which the relayer fee is set.
     * @param _fee The new relayer fee to be set.
     */
    function setDestinationRelayerFee(uint32 _destinationDomain, uint256 _fee) external onlyOwner {
        relayerFeeMaps[_destinationDomain] = _fee;
        emit DestinationRelayerFeeUpdated(_destinationDomain, _fee);
    }

    /**
     * @notice Sets the base fee for a specific destination domain.
     * @dev Only callable by the contract owner.
     * @param _destinationDomain The domain ID for which the base fee is set.
     * @param _fee The new base fee to be set.
     */
    function setDestinationBaseFee(uint32 _destinationDomain, uint256 _fee) external onlyOwner {
        baseFeeMaps[_destinationDomain] = _fee;
        emit DestinationBaseFeeUpdated(_destinationDomain, _fee);
    }

    /**
     * @notice Updates the delegate fee amount.
     * @dev Only callable by the contract owner.
     * @param _newFee The new delegate fee to be set.
     */
    function setDelegateFee(uint256 _newFee) external onlyOwner {
        delegateFee = _newFee;
        emit DelegateFeeUpdated(_newFee);
    }

    /**
     * @notice Updates the service fee percentage.
     * @dev Only callable by the contract owner.
     * @param _newFeeBPS The new service fee in BPS
     */
    function setServiceFee(uint256 _newFeeBPS) external onlyOwner {
        serviceFeeBPS = _newFeeBPS;
        emit ServiceFeeUpdated(_newFeeBPS);
    }

    /**
     * @notice Set the status for multiple delegators at once.
     * @dev Only callable by the contract owner. Emits a `DelegatorUpdated` event for each updated delegator.
     * @param _delegators An array of delegator addresses to update.
     * @param _status The new status (true or false) to be set for the given delegators.
     */
    function setDelegators(address[] memory _delegators, bool _status) external onlyOwner {
        for (uint256 i = 0; i < _delegators.length; i++) {
            delegators[_delegators[i]] = _status;
            emit DelegatorUpdated(_delegators[i], _status);
        }
    }

    /**
     * @notice Pauses all functionality of the contract.
     * @dev Only callable by the contract owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Resumes all paused functionalities of the contract.
     * @dev Only callable by the contract owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Returns the maximum of two given numbers.
     * @param a First number.
     * @param b Second number.
     * @return The maximum of the two numbers.
     */
    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }
}
