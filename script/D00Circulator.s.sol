// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import "../src/Circulator.sol";
import "../src/CirculatorProxy.sol";
import "./utils/DeployHelper.sol";

contract Deploy is Script, DeployHelper {
    mapping(uint256 chainId => address) circulator;

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
        uint256 chainId = block.chainid;
        console2.log("Deploying Circulator on chain: ", chainId);

        address[] memory delegators = new address[](1);
        delegators[0] = msg.sender;

        DeployConfig memory config = getConfig(chainId, msg.sender, msg.sender, delegators);

        address implementation =
            address(new Circulator(config.usdc, config.tokenMessenger, config.tokenMinter, config.v3SpokePool));

        circulator[chainId] = address(
            new CirculatorProxy(
                implementation,
                abi.encodeWithSelector(
                    Circulator.initialize.selector,
                    config.initialOwner,
                    config.feeCollector,
                    config.delegateFee,
                    config.relayerFees,
                    config.delegators
                )
            )
        );

        console2.log("Circulator deployed at: ", circulator[chainId]);

        // Initialize Circulator
        Circulator(circulator[chainId]).initDestinationConfigs(
            config.domainIds, config.relayerFees, config.baseFees, config.chainIds, config.tokens
        );
    }

    function postDeploy() public {}
}
