//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OpenZeppelin/token/ERC20/ERC20.sol";
import "./OpenZeppelin/token/ERC721/ERC721.sol";
import "./OpenZeppelin/token/ERC721/ERC721Holder.sol";

interface Factory {
    function gov() external returns(address payable);
}

contract TokenVault is ERC20, ERC721Holder {

    /// TOKEN INFORMATION
    /// @notice the ERC721 token address of the vault's token
    address public token;

    /// @notice the ERC721 token ID of the vault's token
    uint256 public id;

    /// AUCTION INFORMATION
    /// @notice the unix timestamp end time of the token auction
    uint256 public auctionEnd;

    /// @notice the current price of the token
    uint256 public reservePrice;

    /// @notice the current user winning the token auction
    address payable public winning;

    /// @notice a boolean to indicate if an auction is happening
    bool public auctionLive;

    /// VAULT INFORMATION
    /// @notice the governance contract which gets paid in ETH
    address public factory;

    /// @notice the governance fee for this ERC721 token sale
    uint256 public fee;

    /// @notice a boolean to indicate if the vault has closed
    bool public vaultClosed;

    /// @notice a mapping of users to their desired token price
    mapping(address => uint256) public userPrices;

    /// @notice An event emitted when a user updates their price
    event PriceUpdate(address user, uint price);

    /// @notice An event emitted when a bid is made
    event Bid(address buyer, uint price);

    /// @notice An event emitted when an auction is won
    event Won(address buyer, uint price);

    /// @notice An event emitted when someone redeems all tokens for the NFT
    event Redeem(address redeemer);

    /// @notice An event emitted when someone cashes in ERC20 tokens for ETH from an ERC721 token sale
    event Cash(address owner, uint256 shares);

    constructor(address _factory, uint256 _fee, address _token, uint256 _id, address _account, uint256 _reservePrice, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        factory = _factory;
        fee = _fee;
        token = _token;
        id = _id;
        reservePrice = _reservePrice;
        _mint(_account, 100e18);
        _updateUserPrice(_account, _reservePrice);
    }

    /// @notice a function for an end user to update their desired sale price
    /// @param _price the desired price in ETH
    function updateUserPrice(uint256 _price) external {
        require(!auctionLive, "update:auction live cannot update price");
        uint256 price = userPrices[msg.sender];
        uint256 weight = balanceOf(msg.sender);

        _updateUserPrice(msg.sender, _price);

        reservePrice = reservePrice - (weight * price / totalSupply()) + (weight * _price / totalSupply());
    }

    /// @notice an internal function used to update sender and receivers price on token transfer
    /// @param _from the ERC20 token sender
    /// @param _to the ERC20 token receiver
    /// @param _amount the ERC20 token amount
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override {
        if (_from != address(0) && !auctionLive) {
            uint256 fromPrice = userPrices[_from];
            uint256 toPrice = userPrices[_to] == 0 ? reservePrice : userPrices[_to];

            _updateUserPrice(_to, toPrice);

            // subtract senders votes and add receivers votes
            reservePrice = reservePrice - (_amount * fromPrice / totalSupply()) + (_amount * toPrice / totalSupply());
        }
    }

    /// @notice an internal function to update a users price and emit an event
    /// @param _user the user whos price is being update
    /// @param _price the price the user has chosen in ETH
    function _updateUserPrice(address _user, uint256 _price) internal {
        userPrices[_user] = _price;

        emit PriceUpdate(_user, _price);
    }

    /// @notice an external function to bid on purchasing the vaults NFT. The msg.value is the bid amount
    function bid() external payable {
        // require(msg.sender == tx.origin, "bid:no contracts");
        require(msg.value >= reservePrice * 105 / 100, "bid:too low bid");

        // Give back the last bidders money
        if (winning != address(0)) {
            require(block.timestamp < auctionEnd, "bid:auction ended");
            // If bid is within 15 minutes of auction end, extend auction
            if (auctionEnd - block.timestamp <= 15 minutes) {
                auctionEnd += 15 minutes;
            }
            winning.transfer(reservePrice);
        } else {
            auctionEnd = block.timestamp + 2 days;
            auctionLive = true;
        }

        reservePrice = msg.value;
        winning = payable(msg.sender);

        emit Bid(msg.sender, msg.value);
    }

    /// @notice an external function to end an auction after the timer has run out
    function end() external {
        require(!vaultClosed, "end:vault has already closed");
        require(block.timestamp >= auctionEnd, "end:auction live");

        // transfer erc721 to winner
        IERC721(token).safeTransferFrom(address(this), winning, id);

        uint256 govFee = fee * address(this).balance / 1000;
        payable(Factory(factory).gov()).transfer(govFee);

        auctionLive = false;
        vaultClosed = true;

        emit Won(winning, reservePrice);
    }

    /// @notice an external function to burn all ERC20 tokens to receive the ERC721 token
    function redeem() external {
        _burn(msg.sender, totalSupply());
        // transfer erc721 to redeemer
        IERC721(token).safeTransferFrom(address(this), msg.sender, id);
        vaultClosed = true;

        emit Redeem(msg.sender);
    }

    /// @notice an external function to burn ERC20 tokens to receive ETH from ERC721 token purchase
    function cash() external {
        uint256 bal = balanceOf(msg.sender);
        require(bal > 0, "cash:no tokens to cash out");
        uint256 share = bal * address(this).balance / totalSupply();
        _burn(msg.sender, bal);
        payable(msg.sender).transfer(share);

        emit Cash(msg.sender, share);
    }

}