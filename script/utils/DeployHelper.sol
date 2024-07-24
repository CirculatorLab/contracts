// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

struct DeployConfig {
    address tokenMessenger;
    address localMinter;
    address usdc;
    address initialOwner;
    address feeCollector;
    address[] delegators;
    uint8 sourceChain;
    uint256 delegateFee;
    uint256 serviceFeeBPS;
    uint32[] domainIds;
    uint256[] relayerFees;
    uint256[] baseFees;
}

abstract contract DeployHelper {
    mapping(uint256 chainId => DeployConfig) public deployConfigs;

    constructor() {
        uint32[6] memory domainIds = [uint32(0), uint32(1), uint32(2), uint32(3), uint32(6), uint32(7)];
        uint256[6] memory relayerFees = [
            uint256(1 * 1e6),
            uint256(0.1 * 1e6),
            uint256(0.1 * 1e6),
            uint256(0.1 * 1e6),
            uint256(0.1 * 1e6),
            uint256(0.1 * 1e6)
        ];
        uint256[6] memory baseFees = [
            uint256(1 * 1e6),
            uint256(0.1 * 1e6),
            uint256(0.1 * 1e6),
            uint256(0.1 * 1e6),
            uint256(0.1 * 1e6),
            uint256(0.1 * 1e6)
        ];

        // EthereumSepolia
        DeployConfig storage config = deployConfigs[11155111];
        config.tokenMessenger = 0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5;
        config.localMinter = 0xE997d7d2F6E065a9A93Fa2175E878Fb9081F1f0A;
        config.usdc = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
        config.sourceChain = 0;
        config.delegateFee = 0.5 * 1e6;
        config.serviceFeeBPS = 10;
        config.domainIds = domainIds;
        config.relayerFees = relayerFees;
        config.baseFees = baseFees;

        // AvalancheFuji
        config = deployConfigs[43113];
        config.tokenMessenger = 0xeb08f243E5d3FCFF26A9E38Ae5520A669f4019d0;
        config.localMinter = 0x4ED8867f9947A5fe140C9dC1c6f207F3489F501E;
        config.usdc = 0x5425890298aed601595a70AB815c96711a31Bc65;
        config.sourceChain = 1;
        config.delegateFee = 0.05 * 1e6;
        config.serviceFeeBPS = 10;
        config.domainIds = domainIds;
        config.relayerFees = relayerFees;
        config.baseFees = baseFees;

        // OPSepolia
        config = deployConfigs[11155420];
        config.tokenMessenger = 0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5;
        config.localMinter = 0xE997d7d2F6E065a9A93Fa2175E878Fb9081F1f0A;
        config.usdc = 0x5fd84259d66Cd46123540766Be93DFE6D43130D7;
        config.sourceChain = 2;
        config.delegateFee = 0.05 * 1e6;
        config.serviceFeeBPS = 10;
        config.domainIds = domainIds;
        config.relayerFees = relayerFees;
        config.baseFees = baseFees;

        // Arbitrum Sepolia
        config = deployConfigs[421614];
        config.tokenMessenger = 0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5;
        config.localMinter = 0xE997d7d2F6E065a9A93Fa2175E878Fb9081F1f0A;
        config.usdc = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d;
        config.sourceChain = 3;
        config.delegateFee = 0.05 * 1e6;
        config.serviceFeeBPS = 10;
        config.domainIds = domainIds;
        config.relayerFees = relayerFees;
        config.baseFees = baseFees;

        // BaseSepolia
        config = deployConfigs[84532];
        config.tokenMessenger = 0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5;
        config.localMinter = 0xE997d7d2F6E065a9A93Fa2175E878Fb9081F1f0A;
        config.usdc = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
        config.sourceChain = 6;
        config.delegateFee = 0.05 * 1e6;
        config.serviceFeeBPS = 10;
        config.domainIds = domainIds;
        config.relayerFees = relayerFees;
        config.baseFees = baseFees;

        // Polygon Amoy
        config = deployConfigs[80002];
        config.tokenMessenger = 0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5;
        config.localMinter = 0xE997d7d2F6E065a9A93Fa2175E878Fb9081F1f0A;
        config.usdc = 0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582;
        config.sourceChain = 7;
        config.delegateFee = 0.05 * 1e6;
        config.serviceFeeBPS = 10;
        config.domainIds = domainIds;
        config.relayerFees = relayerFees;
        config.baseFees = baseFees;
    }

    function getConfig(uint256 chainId, address _initialOwner, address _feeCollector, address[] memory _delegators)
        public
        view
        returns (DeployConfig memory)
    {
        DeployConfig memory config = deployConfigs[chainId];
        config.initialOwner = _initialOwner;
        config.feeCollector = _feeCollector;
        config.delegators = _delegators;

        if ((uint160(config.tokenMessenger) & uint160(config.usdc) & uint160(config.localMinter)) == (0)) {
            revert("Not config on this chain");
        }

        return config;
    }
}
