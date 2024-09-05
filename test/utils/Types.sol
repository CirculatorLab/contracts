// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICirculator} from "../../src/interfaces/ICirculator.sol";

struct DelegateParams {
    uint256 pk;
    uint256 nonce;
    uint32 destDomain;
    uint32 fillDeadline;
    ICirculator.CirculateType circulateType;
    address recipient;
    uint256 outputAmount;
}
