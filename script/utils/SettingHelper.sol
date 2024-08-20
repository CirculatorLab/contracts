// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

struct SystemConfig {
    address circulator;
    address usdc;
}

abstract contract SettingHelper {
    mapping(uint256 => SystemConfig) public systemConfigs;

    constructor() {
        // Ethereum Sepolia
        SystemConfig storage config = systemConfigs[11155111];
        config.circulator = 0x4A62C58c9c788d31A9426e6878d017a68328A052;
        config.usdc = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;

        // AvalancheFuji
        config = systemConfigs[43113];
        config.circulator = 0x86C64D50c68e00a2AF9BE51a3EBD009995403eBd;
        config.usdc = 0x5425890298aed601595a70AB815c96711a31Bc65;

        // OPSepolia
        config = systemConfigs[11155420];
        config.circulator = 0x75D6C315040482f0Ad4838f9B11A2F7B6a19afC1;
        config.usdc = 0x5fd84259d66Cd46123540766Be93DFE6D43130D7;

        // Arbitrum Sepolia
        config = systemConfigs[421614];
        config.circulator = 0x86C64D50c68e00a2AF9BE51a3EBD009995403eBd;
        config.usdc = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d;

        // BaseSepolia
        config = systemConfigs[84532];
        config.circulator = 0x005C57acB4Dd229e8B2E1ba1bC7439C93eCBD9F9;
        config.usdc = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

        // PolygonPoSAmoy
        config = systemConfigs[80002];
        config.circulator = 0x86C64D50c68e00a2AF9BE51a3EBD009995403eBd;
        config.usdc = 0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582;
    }

    function getConfig(uint256 chainId) public view returns (SystemConfig memory) {
        SystemConfig memory config = systemConfigs[chainId];
        if (config.circulator == address(0)) {
            revert("Circulator not deployed on this chain.");
        }
        return config;
    }
}
