build  :; dapp --use solc:0.8.5 build
clean  :; dapp clean
test   :; dapp --use solc:0.8.5 build; hevm dapp-test --rpc=https://mainnet.infura.io/v3/73dc63290c73465d8b659ce17028909f --json-file=out/dapp.sol.json --dapp-root=. --verbose 1
deploy-settings :; dapp create --verify Settings
deploy-testnet :; dapp create --verify ERC721VaultFactory