## Deployments

```shell
# Load ENV
source .env
```

```shell
# Deploy on OP Sepolia
DEPLOY_CHAIN=OPSepolia forge script script/D00Circulator.s.sol --broadcast --verify --rpc-url optimism_sepolia --private-key $PRIVATE_KEY
```

```shell
# Setup delegators on OP Sepolia
DEPLOY_CHAIN=OPSepolia forge script script/D01SetDelegator.s.sol --broadcast --rpc-url optimism_sepolia --private-key $PRIVATE_KEY
```

```shell
# Deploy on BASE Sepolia
DEPLOY_CHAIN=BaseSepolia forge script script/D00Circulator.s.sol --broadcast --verify --rpc-url base_sepolia --private-key $PRIVATE_KEY
```

```shell
# Setup delegators on Base Sepolia
DEPLOY_CHAIN=BaseSepolia forge script script/D01SetDelegator.s.sol --broadcast --rpc-url base_sepolia --private-key $PRIVATE_KEY
```

```shell
# Set Base Fee Map
cast send <CIRCULATOR_ADDRESS> "setDestinationMinFee(uint32,uint256)" <CHAIN_ID> <BASE_FEE> --private-key $PRIVATE_KEY --rpc-url <CHAIN_ALIAS>
```