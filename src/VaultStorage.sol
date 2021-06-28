//SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

contract VaultStorage {

    /// -----------------------------------
    /// -------- BASIC INFORMATION --------
    /// -----------------------------------

    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public logic;

    /// -----------------------------------
    /// -------- ERC721 INFORMATION -------
    /// -----------------------------------

    address public token;
    uint256 public id;

    /// -----------------------------------
    /// -------- ERC20 INFORMATION --------
    /// -----------------------------------
    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    /// -------------------------------------
    /// -------- AUCTION INFORMATION --------
    /// -------------------------------------

    /// @notice the unix timestamp end time of the token auction
    uint256 public auctionEnd;

    /// @notice the length of auctions
    uint256 public auctionLength;

    /// @notice reservePrice * votingTokens
    uint256 public reserveTotal;

    /// @notice the current price of the token during an auction
    uint256 public livePrice;

    /// @notice the current user winning the token auction
    address payable public winning;

    enum State { inactive, live, ended, redeemed }

    State public auctionState;

    /// -----------------------------------
    /// -------- VAULT INFORMATION --------
    /// -----------------------------------

    /// @notice the governance contract which gets paid in ETH
    address public settings;

    /// @notice the address who initially deposited the NFT
    address public curator;

    /// @notice the AUM fee paid to the curator yearly. 3 decimals. ie. 100 = 10%
    uint256 public fee;

    /// @notice the last timestamp where fees were claimed
    uint256 public lastClaimed;

    /// @notice a boolean to indicate if the vault has closed
    bool public vaultClosed;

    /// @notice the number of ownership tokens voting on the reserve price at any given time
    uint256 public votingTokens;

    /// @notice a mapping of users to their desired token price
    mapping(address => uint256) public userPrices;

}