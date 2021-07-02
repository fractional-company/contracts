# Fractional contracts

## Settings
This is a generic settings contract to be owned by governance. It is gated by some high and low boundary values. It allows for governance to set parameters for all Token Vaults.

## Vault Factory
This is a simple factory where a user can call `mint` to create a new vault with the token that they want to fractionalize. The user must pass in:
- an ERC20 token desired name
- an ERC20 token desired symbol
- the ERC721 token address they wish to fractionalize
- the ERC721 token id they wish to fractionalize
- the desired ERC20 token supply
- the initial listing price of the NFT
- their desired curator fee

## Initialized Proxy
A minimal proxy contract to represent vaults which allows for cheap deployments.

## Token Vault
The token vault is the smart contract which holds the logic for NFTs that have been fractionalized.

Token holders are able to update the reserve price with a weighted average of all token holders reserve prices. This is done automatically on token transfer to new accounts or manually through `updateUserPrice`.

Alongside this logic, is auction logic which allows for an outside user to initial a buyout auction of the NFT. Here there are `start`, `bid`, `end` and `cash` functions.
#### Start
The function called to kick off an auction. `msg.value` must be greater than or equal to the current reserve price.
#### Bid
The function called for all subsequent auction bids.
#### End
The function called when the auction timer is up and ended.
#### Cash
The function called for token holders to cash out their share of the ETH used to purchase the underlying NFT.

There is also some admin logic for the `curator` (user who initially deposited the NFT). They can reduce their fee or change the auction length. Alongside this, they are able to claim fees in the form of token supply inflation.

## IndexERC721
This is a single token ERC721 which is used to custody multiple ERC721 tokens. 
#### depositERC721
Anyone can deposit an ERC721 token into the contract
#### withdrawERC721
The token holder can withdraw any ERC721 tokens in the contract
#### withdrawETH
The token holder can withdraw any ETH in the contract
#### withdrawERC20
The token holder can withdraw any ERC20 token in the contract

## Deployments
### Mainnet
[Vault Factory](https://etherscan.io/address/0x85aa7f78bdb2de8f3e0c0010d99ad5853ffcfc63)
[Token Vault](https://etherscan.io/address/0x7b0fce54574d9746414d11367f54c9ab94e53dca)
[Settings](https://etherscan.io/address/0xE0FC79183a22106229B84ECDd55cA017A07eddCa)
[Index ERC721 Factory](https://etherscan.io/address/0xde771104c0c44123d22d39bb716339cd0c3333a1)

### Rinkeby
[Vault Factory](https://rinkeby.etherscan.io/address/0x458556c097251f52ca89cB81316B4113aC734BD1)
[Token Vault](https://rinkeby.etherscan.io/address/0x825f25f908db46daEA42bd536d25f8633667f62b)
[Settings](https://rinkeby.etherscan.io/address/0x1C0857f8642D704ecB213A752A3f68E51913A779)
[Index ERC721 Factory](https://rinkeby.etherscan.io/address/0xee727b734aC43fc391b67caFd18e5DD4Dc939668)

