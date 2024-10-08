// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// Interfaces
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ITokenMessenger} from "./interfaces/ITokenMessenger.sol";
import {ITokenMinter} from "./interfaces/ITokenMinter.sol";
import {IV3SpokePool} from "./interfaces/IV3SpokePool.sol";
import {ICirculator} from "./interfaces/ICirculator.sol";

// Inherited contracts
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// Libraries
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @author CirculatorLabs
contract Circulator is
    ICirculator,
    Nonces,
    PausableUpgradeable,
    OwnableUpgradeable,
    EIP712Upgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    bytes32 public constant DELEGATE_CIRCULATE_TYPEHASH = keccak256(
        "DelegateCirculate(uint32 destinationDomain,uint32 fillDeadline,uint8 circulateType,address recipient,uint256 outputAmount,uint256 nonce)"
    );

    ///@dev asset to be circulated.
    address public immutable circleAsset;

    ///@dev Circle TokenMessenger contract.
    ITokenMessenger public immutable tokenMessenger;

    ///@dev Circle TokenMinter contract.
    ITokenMinter public immutable tokenMinter;

    ///@dev Across SpokePool contract.
    IV3SpokePool public immutable v3SpokePool;

    ///@dev Fee Collector address.
    address public feeCollector;

    ///@dev Fee for delegators. denominated in circleAsset
    uint256 public delegateFee;

    ///@dev Service fee in BPS
    uint256 public serviceFeeBPS;

    ///@dev Mapping of destination domain to configs(relayer fee, base fee, chainId, token).
    mapping(uint32 destinationDomain => DestinationCofigs) public destinationConfigs;

    ///@dev Mapping of authorized delegators
    mapping(address delegator => bool) public delegators;

    /**
     * @param _tokenMessenger Address of the tokenMessenger contract.
     * @param _tokenMinter Address of the tokenMinter contract.
     * @param _v3SpokePool Address of the v3SpokePool contract.
     */
    constructor(address _circleAsset, address _tokenMessenger, address _tokenMinter, address _v3SpokePool) {
        circleAsset = _circleAsset;
        tokenMessenger = ITokenMessenger(_tokenMessenger);
        tokenMinter = ITokenMinter(_tokenMinter);
        v3SpokePool = IV3SpokePool(_v3SpokePool);
    }

    function initialize(
        address _initialOwner,
        address _feeCollector,
        uint256 _delegateFee,
        uint256 _serviceFeeBPS,
        address[] memory _delegators
    ) public initializer {
        __Ownable_init(_initialOwner);

        __Pausable_init();
        __EIP712_init_unchained("Circulator", "v1");
        __UUPSUpgradeable_init();

        feeCollector = _feeCollector;

        IERC20(circleAsset).safeIncreaseAllowance(address(tokenMessenger), type(uint256).max);
        IERC20(circleAsset).safeIncreaseAllowance(address(v3SpokePool), type(uint256).max);

        // Set approved delegators
        for (uint256 i = 0; i < _delegators.length; i++) {
            delegators[_delegators[i]] = true;
        }

        // Source chain fixed fee
        delegateFee = _delegateFee;
        // Service fee in BPS
        serviceFeeBPS = _serviceFeeBPS;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @notice Modifier to ensure that only the fee collector can call a function.
     * @dev Throws an error if the caller is not the fee collector.
     */
    modifier onlyFeeCollector() {
        require(msg.sender == feeCollector, "not fee collector");
        _;
    }

    /**
     * @notice Modifier to ensure that a given burn amount for a token doesn't exceed the allowed burn limit.
     * @dev Queries the `burnLimitsPerMessage` from the `tokenMinter` to get the maximum allowed burn amount for the token.
     * @param amount The amount of the token being requested to burn.
     */
    modifier onlyWithinBurnLimit(uint256 amount) {
        uint256 _allowedBurnAmount = tokenMinter.burnLimitsPerMessage(circleAsset);
        if (amount > _allowedBurnAmount) revert BurnAmountExceedsLimit();
        _;
    }

    /**
     * @notice Circulate a specified amount to the destination domain and emits a `Circulate` event.
     * @dev This function burns a token amount for the given recipient and destination domain.
     * @param _inputAmount Amount to circulate.
     * @param _recipient The address of the recipient in bytes32 format.
     * @param _destinationDomain The ID of the destination domain.
     * @param _type Circulate type: Cctp or Across.
     * @return nonce Burn nonce for the circulate.
     */
    function circulate(
        uint256 _inputAmount,
        uint256 _outputAmount,
        address _recipient,
        uint32 _destinationDomain,
        uint32 _fillDeadline,
        CirculateType _type
    ) external whenNotPaused onlyWithinBurnLimit(_inputAmount) returns (uint64 nonce) {
        // Check if fee is covered
        uint256 fee = totalFee(_inputAmount, _destinationDomain, _type);
        if (fee > _inputAmount) revert FeeNotCovered();

        // Burn the token in TokenMessenger
        IERC20(circleAsset).safeTransferFrom(msg.sender, address(this), _inputAmount);

        nonce = _circulate(
            msg.sender, _recipient, _inputAmount, _outputAmount, fee, _destinationDomain, _fillDeadline, _type
        );
    }

    /**
     * @notice Circulate on behalf of a user with signatures
     * @dev This function can only be trusted when circleAsset is set to a valid ERC20 token from Circle, with `permit` functionality.
     *      If a token doesn't have permit but has a fallback function, this could lead to potential attack.
     * @dev In the current version, only whitelisted delegator can call this function to circulate on behalf of other users.
     * @param permitData Data needed for the permit.
     * @param delegateData Data needed for the delegate.
     * @return nonce Burn nonce for the circulate.
     */
    // slither-disable-next-line arbitrary-send-erc20-permit
    function delegateCirculate(PermitData calldata permitData, DelegateData calldata delegateData)
        external
        whenNotPaused
        onlyWithinBurnLimit(permitData.amount)
        returns (uint64 nonce)
    {
        if (!delegators[msg.sender]) revert NotDelegator();

        // Calculate delegate mode fee
        uint256 fee =
            totalFee(permitData.amount, delegateData.destinationDomain, delegateData.circulateType) + delegateFee;
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

        // Verify the delegate data and signature
        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATE_CIRCULATE_TYPEHASH,
                delegateData.destinationDomain,
                delegateData.fillDeadline,
                delegateData.circulateType,
                delegateData.recipient,
                delegateData.outputAmount,
                _useNonce(permitData.sender)
            )
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, delegateData.v, delegateData.r, delegateData.s);
        if (signer != permitData.sender) {
            revert InvalidDelegateSignature();
        }

        nonce = _circulate(
            permitData.sender,
            delegateData.recipient,
            permitData.amount,
            delegateData.outputAmount,
            fee,
            delegateData.destinationDomain,
            delegateData.fillDeadline,
            delegateData.circulateType
        );
    }

    function _circulate(
        address _sender,
        address _recipient,
        uint256 _inputAmount,
        uint256 _outputAmount,
        uint256 _fee,
        uint32 _destinationDomain,
        uint32 _fillDeadline,
        CirculateType _type
    ) internal returns (uint64 nonce) {
        uint256 inputAmount = _inputAmount - _fee;
        if (inputAmount < _outputAmount) revert InsufficientInputAmount();

        if (_type == CirculateType.Cctp) {
            nonce = tokenMessenger.depositForBurn(
                inputAmount, _destinationDomain, bytes32(uint256(uint160(_recipient))), circleAsset
            );
        } else if (_type == CirculateType.Across) {
            nonce = v3SpokePool.numberOfDeposits();
            v3SpokePool.depositV3(
                _sender, // depositor
                _recipient, // recipient
                circleAsset, // inputToken
                destinationConfigs[_destinationDomain].token, // outputToken
                inputAmount, // inputAmount
                _outputAmount, // outputAmount
                destinationConfigs[_destinationDomain].chainId, // destinationChainId
                address(0), // exclusiveRelayer
                uint32(block.timestamp), // quoteTimestamp
                _fillDeadline, // fillDeadline
                0, // exclusivityDeadline
                "" // message
            );
        }

        // Emit an event
        emit Circulate(_sender, _recipient, _destinationDomain, inputAmount, _fee, nonce, msg.sender, _type);
    }

    /**
     * @notice Calculates the total fee for a given amount and destination domain.
     * @dev The function computes the service fee for the provided amount and adds the relayer fee
     * associated with the specified destination domain. The total fee is the greater of the sum
     * or the base fee associated with the destination domain.
     * @param _amount Amount for which the fee needs to be calculated.
     * @param _destinationDomain The domain ID for which relayer and base fees are fetched.
     * @param _type Circulate type: Cctp or Across.
     * @return _finalFee The total fee denominated in circleAsset
     */
    function totalFee(uint256 _amount, uint32 _destinationDomain, CirculateType _type)
        public
        view
        returns (uint256 _finalFee)
    {
        uint256 relayerFee = _type == CirculateType.Cctp ? destinationConfigs[_destinationDomain].relayerFee : 0;
        uint256 txFee = getServiceFee(_amount) + relayerFee;
        _finalFee = _max(txFee, destinationConfigs[_destinationDomain].minFee);
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
     * @notice Initializes the destination domain configurations.
     * @dev Only callable by the contract owner.
     * @param _domainIds List of domain IDs.
     * @param _relayerFees List of relayer fees corresponding to each domain ID.
     * @param _minFees List of base fees corresponding to each domain ID.
     * @param _chainIds List of chain IDs corresponding to each domain ID.
     * @param _tokens List of token addresses corresponding to each domain ID.
     */
    function initDestinationConfigs(
        uint32[] memory _domainIds,
        uint256[] memory _relayerFees,
        uint256[] memory _minFees,
        uint256[] memory _chainIds,
        address[] memory _tokens
    ) external onlyOwner {
        for (uint256 i = 0; i < _domainIds.length; i++) {
            if (_chainIds[i] == 0 || _tokens[i] == address(0)) revert InvalidConfig();
            destinationConfigs[_domainIds[i]] = DestinationCofigs({
                relayerFee: _relayerFees[i],
                minFee: _minFees[i],
                chainId: _chainIds[i],
                token: _tokens[i]
            });
        }
    }

    /**
     * @notice Sets the relayer fee for a specific destination domain.
     * @dev Only callable by the contract owner.
     * @param _destinationDomain The domain ID for which the relayer fee is set.
     * @param _fee The new relayer fee to be set.
     */
    function setDestinationRelayerFee(uint32 _destinationDomain, uint256 _fee) external onlyOwner {
        destinationConfigs[_destinationDomain].relayerFee = _fee;
        emit DestinationRelayerFeeUpdated(_destinationDomain, _fee);
    }

    /**
     * @notice Sets the base fee for a specific destination domain.
     * @dev Only callable by the contract owner.
     * @param _destinationDomain The domain ID for which the base fee is set.
     * @param _fee The new base fee to be set.
     */
    function setDestinationMinFee(uint32 _destinationDomain, uint256 _fee) external onlyOwner {
        destinationConfigs[_destinationDomain].minFee = _fee;
        emit DestinationMinFeeUpdated(_destinationDomain, _fee);
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
     * @notice Updates the fee collector address.
     * @dev Only callable by the contract owner.
     * @param _feeCollector The new fee collector address to be set.
     */
    function setFeeCollector(address _feeCollector) external onlyOwner {
        if (_feeCollector == address(0)) revert ZeroAddress();
        feeCollector = _feeCollector;
        emit FeeCollectorUpdated(_feeCollector);
    }

    /**
     * @notice Returns the destination domain configurations.
     * @param _destinationDomain The domain ID for which the configurations are fetched.
     * @return _configs The destination domain configurations.
     */
    function getDestinationConfigs(uint32 _destinationDomain) external view returns (DestinationCofigs memory) {
        return destinationConfigs[_destinationDomain];
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
     * @dev Only fee collector can collect fees. This contract should only hold circleAsset, but can also be used to rescue mistakenly sent tokens.
     * @param _tokens ERC20 token address
     * @param _to Recipient address
     */
    function collectFee(address _tokens, address _to) external onlyFeeCollector {
        uint256 balance = IERC20(_tokens).balanceOf(address(this));
        IERC20(_tokens).safeTransfer(_to, balance);
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
