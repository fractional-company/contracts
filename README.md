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

## Token Vault
The token vault is the smart contract which holds the NFT that has been fractionalized. It also is the contract for the ERC20 token which represents the fractional ownership of the stored NFT.

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

There is also some admin logic for the `curator` (user who initially deposited the NFT). They can reduce their fee, change the auction length, or update the base price. Alongside this, they are able to claim fees in the form of token supply inflation.

