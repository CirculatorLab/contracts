// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/Circulator.sol";
import "./utils/SettingHelper.sol";

contract SetDelegator is Script, SettingHelper {
    mapping(string => address) circulator;

    function run() public {
        vm.startBroadcast();
        preDeploy();
        deploy();
        postDeploy();
        vm.stopBroadcast();
    }

    function preDeploy() public {}

    function deploy() public {
        console2.log("Set Delegators with owner address: ", msg.sender, "and balance: ", address(msg.sender).balance);
        // Deploy Circulator
        string memory currentChain = vm.envString("DEPLOY_CHAIN");
        console2.log("Set Delegators chain: ", currentChain);

        SystemConfig memory config = getConfig(currentChain);

        address[] memory delegators = new address[](2);
        delegators[0] = 0x39329eEa71745B8AD98c51d4287A280e141D9bC6;
        delegators[1] = 0x29C3d6b54E2F8Ae641Fc331cF2143B6d05c97897;

        console2.log("Circulator address: ", config.circulator);
        (bool success,) =
            address(config.circulator).call(abi.encodeWithSignature("setDelegators(address[],bool)", delegators, true));
        console2.log("Set Delegators success: ", success);
    }

    function postDeploy() public {}
}
