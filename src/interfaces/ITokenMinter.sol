// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/// @author CirculatorLabs
/// @title IBurnLimit
/// @dev This interface is used to check burn limits from CCTP's local minter.
interface ITokenMinter {
    /// @notice Fetches the burn limit for a specific address.
    /// @param _address The address for which to fetch the burn limit.
    /// @return Returns the burn limit for the provided address.
    function burnLimitsPerMessage(address _address) external view returns (uint256);
}
