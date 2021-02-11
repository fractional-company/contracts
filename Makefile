build  :; dapp --use solc:0.8.0 build
clean  :; dapp clean
test   :; dapp --use solc:0.8.0 build; hevm dapp-test --rpc=YOURPC --json-file=out/dapp.sol.json --dapp-root=. --verbose 1
deploy :; dapp create NibbleCore