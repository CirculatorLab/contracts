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
        config.circulator = 0x04b74013b1a0CBc8fbDBc443b089e6F426C71B99;

        // AvalancheFuji
        config = systemConfigs[43113];
        config.circulator = 0x0Ad523F62f9BC5748118f25647618092610b6760;

        // OPSepolia
        config = systemConfigs[11155420];
        config.circulator = 0xbFFDC2a29ccB1D893939AB4132553F9Fe998b546;

        // Arbitrum Sepolia
        config = systemConfigs[421614];
        config.circulator = 0x52351dF87889693EB5ACA0e64bf223D263dE9c24;

        // BaseSepolia
        config = systemConfigs[84532];
        config.circulator = 0x538d78c2d84eFa321F68c115A59058eE5f671674;

        // PolygonPoSAmoy
        config = systemConfigs[80002];
        config.circulator = 0x52351dF87889693EB5ACA0e64bf223D263dE9c24;
    }

    function getConfig(uint256 chainId) public view returns (SystemConfig memory) {
        SystemConfig memory config = systemConfigs[chainId];
        if (config.circulator == address(0)) {
            revert("Circulator not deployed on this chain.");
        }
        return config;
    }
}
