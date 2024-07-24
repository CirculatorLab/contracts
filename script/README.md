# Scripts

```shell
# Load ENV
source .env
```

## Deployment

```shell
forge script script/D00Circulator.s.sol --broadcast --verify --rpc-url <CHAIN_ALIAS> --private-key $PRIVATE_KEY
```

## Set configuration

### Setup delegators

```shell
forge script script/D01SetDelegator.s.sol --broadcast --rpc-url <CHAIN_ALIAS> --private-key $PRIVATE_KEY
```

### Set other configs with cast

```shell
# Set Base Fee
cast send <CIRCULATOR_ADDRESS> "setDestinationMinFee(uint32,uint256)" <DEST_DOMAIN_ID> <BASE_FEE> --private-key $PRIVATE_KEY --rpc-url <CHAIN_ALIAS>
```

