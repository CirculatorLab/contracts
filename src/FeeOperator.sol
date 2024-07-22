// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/access/Ownable.sol";

abstract contract FeeOperator is Ownable {
    using SafeERC20 for IERC20;

    address public feeCollector;

    event FeeCollectorUpdated(address from, address to);

    modifier onlyFeeCollector() {
        require(msg.sender == feeCollector, "not fee collector");
        _;
    }

    constructor(address _initialOwner, address _feeCollector) Ownable(_initialOwner) {
        feeCollector = _feeCollector;
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

    function setFeeCollector(address _feeCollector) external onlyOwner {
        address oldFeeCollector = feeCollector;
        feeCollector = _feeCollector;
        emit FeeCollectorUpdated(oldFeeCollector, _feeCollector);
    }
}
