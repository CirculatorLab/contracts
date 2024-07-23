// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

struct SystemConfig {
    address circulator;
    address tokenMessenger;
    address usdc;
}

abstract contract SettingHelper {
    mapping(string => SystemConfig) public systemConfigs;

    constructor() {
        SystemConfig storage config = systemConfigs["EthereumSepolia"];
        config.circulator = address(0);
        config.tokenMessenger = 0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5;
        config.usdc = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;

        config = systemConfigs["AvalancheFuji"];
        config.circulator = address(0);
        config.tokenMessenger = 0xeb08f243E5d3FCFF26A9E38Ae5520A669f4019d0;
        config.usdc = 0x5425890298aed601595a70AB815c96711a31Bc65;

        config = systemConfigs["OPSepolia"];
        config.circulator = 0x75D6C315040482f0Ad4838f9B11A2F7B6a19afC1; // Updated after deployment
        config.tokenMessenger = 0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5;
        config.usdc = 0x5fd84259d66Cd46123540766Be93DFE6D43130D7;

        config = systemConfigs["ArbitrumSepolia"];
        config.circulator = address(0);
        config.tokenMessenger = 0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5;
        config.usdc = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d;

        config = systemConfigs["BaseSepolia"];
        config.circulator = 0xa937d41d7F28EEbE18eD697C99cEfaF8B5590aE2;
        config.tokenMessenger = 0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5;
        config.usdc = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

        config = systemConfigs["PolygonPoSAmoy"];
        config.circulator = address(0);
        config.tokenMessenger = 0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5;
        config.usdc = 0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582;
    }

    function getConfig(string memory chainName) public view returns (SystemConfig memory) {
        SystemConfig memory config = systemConfigs[chainName];
        return config;
    }
}
