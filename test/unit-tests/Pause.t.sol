// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {UnitTestBase} from "./Base.t.sol";

contract PauseTest is UnitTestBase {
    function test_Pause() public {
        // Act
        vm.prank(owner);
        circulator.pause();

        // Assert
        assertEq(circulator.paused(), true);

        // Act
        vm.prank(owner);
        circulator.unpause();

        // Assert
        assertEq(circulator.paused(), false);
    }
}
