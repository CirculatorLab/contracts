// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "../../src/interfaces/ITokenMinter.sol";

contract MockTokenMinter is ITokenMinter {
    mapping(address => uint256) private _mockedBurnLimit;

    function burnLimitsPerMessage(address _address) external view override returns (uint256) {
        return _mockedBurnLimit[_address];
    }

    function setBurnLimit(address _address, uint256 _burnLimit) external {
        _mockedBurnLimit[_address] = _burnLimit;
    }
}
