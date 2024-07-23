// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import "../src/Circulator.sol";
import "./utils/DeployHelper.sol";

contract Deploy is Script, DeployHelper {
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
        console2.log(
            "Deploying Circulator with deployer address: ", msg.sender, "and balance: ", address(msg.sender).balance
        );
        // Deploy Circulator
        string memory currentChain = vm.envString("DEPLOY_CHAIN");
        console2.log("Deploying Circulator for chain: ", currentChain);

        address[] memory delegators = new address[](1);
        delegators[0] = msg.sender;

        DeployConfig memory config = getConfig(currentChain, msg.sender, msg.sender, delegators);

        circulator[currentChain] = address(
            new Circulator(
                config.usdc,
                config.tokenMessenger,
                config.localMinter,
                config.initialOwner,
                config.feeCollector,
                config.delegators,
                config.delegateFee,
                config.serviceFeeBPS,
                config.domainIds,
                config.relayerFees,
                config.baseFees
            )
        );
    }

    function postDeploy() public {}
}
