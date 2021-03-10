//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Interfaces/IWETH.sol";
import "./OpenZeppelin/math/Math.sol";
import "./OpenZeppelin/token/ERC20/ERC20.sol";
import "./OpenZeppelin/token/ERC721/ERC721.sol";
import "./OpenZeppelin/token/ERC721/ERC721Holder.sol";

import "./Settings.sol";

contract TokenVault is ERC20, ERC721Holder {

    /// -----------------------------------
    /// -------- BASIC INFORMATION --------
    /// -----------------------------------

    /// @notice weth address
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// -----------------------------------
    /// -------- TOKEN INFORMATION --------
    /// -----------------------------------

    /// @notice the ERC721 token address of the vault's token
    address public token;

    /// @notice the ERC721 token ID of the vault's token
    uint256 public id;

    /// -------------------------------------
    /// -------- AUCTION INFORMATION --------
    /// -------------------------------------

    /// @notice the unix timestamp end time of the token auction
    uint256 public auctionEnd;

    /// @notice the length of auctions
    uint256 public auctionLength;

    /// @notice the price set by the initial lister, can be changed by governance
    uint256 public basePrice;

    /// @notice the current reserve price of the token
    uint256 public reservePrice;

    /// @notice the current price of the token during an auction
    uint256 public livePrice;

    /// @notice the current user winning the token auction
    address payable public winning;

    /// @notice a boolean to indicate if an auction is happening
    bool public auctionLive;

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

    /// @notice a mapping of users to their desired token price
    mapping(address => uint256) public userPrices;

    /// ------------------------
    /// -------- EVENTS --------
    /// ------------------------

    /// @notice An event emitted when a user updates their price
    event PriceUpdate(address user, uint price);

    /// @notice An event emitted when an auction starts
    event Start(address buyer, uint price);

    /// @notice An event emitted when a bid is made
    event Bid(address buyer, uint price);

    /// @notice An event emitted when an auction is won
    event Won(address buyer, uint price);

    /// @notice An event emitted when someone redeems all tokens for the NFT
    event Redeem(address redeemer);

    /// @notice An event emitted when someone cashes in ERC20 tokens for ETH from an ERC721 token sale
    event Cash(address owner, uint256 shares);

    constructor(address _settings, address _curator, address _token, uint256 _id, uint256 _supply, uint256 _listPrice, uint256 _fee, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        settings = _settings;
        token = _token;
        id = _id;
        basePrice = _listPrice;
        reservePrice = _listPrice;
        auctionLength = 7 days;
        curator = _curator;
        fee = _fee;
        lastClaimed = block.timestamp;

        _mint(_curator, _supply);
        _updateUserPrice(_curator, _listPrice);
    }

    /// -----------------------------------
    /// -------- CURATOR FUNCTIONS --------
    /// -----------------------------------

    /// @notice allow curator to update the curator address
    /// @param _curator the new curator
    function updateCurator(address _curator) external {
        require(msg.sender == curator, "update:not curator");

        curator = _curator;
    }

    /// @notice allow curator to update the base price
    /// @param _price the new base price
    function updateBasePrice(uint256 _price) external {
        require(msg.sender == curator, "update:not curator");

        basePrice = _price;
    }

    /// @notice allow curator to update the auction length
    /// @param _length the new base price
    function updateAuctionLength(uint256 _length) external {
        require(msg.sender == curator, "update:not curator");
        require(_length >= ISettings(settings).minAuctionLength() && _length <= ISettings(settings).maxAuctionLength(), "update:invalid auction length");

        auctionLength = _length;
    }

    /// @notice allow the curator to lower their fee
    /// @param _fee the new fee
    function updateFee(uint256 _fee) external {
        require(msg.sender == curator, "update:not curator");
        require(_fee < fee, "update:cannot increase fee");

        _claimFees();

        fee = _fee;
    }

    /// @notice external function to claim fees for the curator and governance
    function claimFees() external {
        _claimFees();
    }

    /// @dev interal fuction to calculate and mint fees
    function _claimFees() internal {
        // get how much in fees the curator would make in a year
        uint256 currentAnnualFee = fee * totalSupply() / 1000; 
        // get how much that is per second;
        uint256 feePerSecond = currentAnnualFee / 31536000;
        // get how many seconds they are eligible to claim
        uint256 sinceLastClaim = block.timestamp - lastClaimed;
        // get the amount of tokens to mint
        uint256 curatorMint = sinceLastClaim * feePerSecond;

        // now lets do the same for governance
        address govAddress = ISettings(settings).feeReceiver();
        uint256 govFee = ISettings(settings).governanceFee();
        currentAnnualFee = govFee * totalSupply() / 1000; 
        feePerSecond = currentAnnualFee / 31536000;
        sinceLastClaim = block.timestamp - lastClaimed;
        uint256 govMint = sinceLastClaim * feePerSecond;

        lastClaimed = block.timestamp;

        _mint(curator, curatorMint);
        _mint(govAddress, govMint);
    }

    /// --------------------------------
    /// -------- CORE FUNCTIONS --------
    /// --------------------------------

    /// @notice a function for an end user to update their desired sale price
    /// @param _new the desired price in ETH
    function updateUserPrice(uint256 _new) external {
        require(!auctionLive, "update:auction live cannot update price");
        uint256 old = userPrices[msg.sender];
        uint256 weight = balanceOf(msg.sender);

        _updateUserPrice(msg.sender, _new);

        reservePrice = reservePrice - (weight * old / totalSupply()) + (weight * _new / totalSupply());
    }

    /// @notice an internal function used to update sender and receivers price on token transfer
    /// @param _from the ERC20 token sender
    /// @param _to the ERC20 token receiver
    /// @param _amount the ERC20 token amount
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override {
        if (_from != address(0) && !auctionLive && !vaultClosed) {
            uint256 fromPrice = userPrices[_from];
            uint256 toPrice = userPrices[_to] == 0 ? reservePrice : userPrices[_to];

            _updateUserPrice(_to, toPrice);

            // subtract senders votes and add receivers votes
            reservePrice = reservePrice - (_amount * fromPrice / totalSupply()) + (_amount * toPrice / totalSupply());

            // make sure the reserve price is within safe bounds
            if (reservePrice < basePrice) {
                uint256 basePriceMin = basePrice * ISettings(settings).minReserveFactor() / 1000;
                reservePrice = Math.max(reservePrice, basePriceMin);
            } else if (reservePrice > basePrice) {
                uint256 basePriceMax = basePrice * ISettings(settings).maxReserveFactor() / 1000;
                reservePrice = Math.min(reservePrice, basePriceMax);
            }
        }
    }

    /// @notice an internal function to update a users price and emit an event
    /// @param _user the user whos price is being update
    /// @param _price the price the user has chosen in ETH
    function _updateUserPrice(address _user, uint256 _price) internal {
        userPrices[_user] = _price;

        emit PriceUpdate(_user, _price);
    }

    /// @notice kick off an auction. Must send reservePrice in ETH
    function start() external payable {
        require(!auctionLive && !vaultClosed, "start:no auction starts");
        require(msg.value >= reservePrice, "start:too low bid");
        
        auctionEnd = block.timestamp + auctionLength;
        auctionLive = true;

        livePrice = msg.value;
        winning = payable(msg.sender);

        emit Start(msg.sender, msg.value);
    }

    /// @notice an external function to bid on purchasing the vaults NFT. The msg.value is the bid amount
    function bid() external payable {
        uint256 increase = ISettings(settings).minBidIncrease() + 1000;
        require(msg.value >= livePrice * increase / 1000, "bid:too low bid");
        require(block.timestamp < auctionEnd, "bid:auction ended");

        // If bid is within 15 minutes of auction end, extend auction
        if (auctionEnd - block.timestamp <= 15 minutes) {
            auctionEnd += 15 minutes;
        }

        _sendETHOrWETH(winning, livePrice);

        livePrice = msg.value;
        winning = payable(msg.sender);

        emit Bid(msg.sender, msg.value);
    }

    /// @notice an external function to end an auction after the timer has run out
    function end() external {
        require(!vaultClosed, "end:vault has already closed");
        require(block.timestamp >= auctionEnd, "end:auction live");

        // transfer erc721 to winner
        IERC721(token).safeTransferFrom(address(this), winning, id);

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

        _sendETHOrWETH(payable(msg.sender), share);

        emit Cash(msg.sender, share);
    }

    /// @dev internal helper function to send ETH and WETH on failure
    function _sendETHOrWETH(address who, uint256 amount) internal {
        // try to send the winner ETH back
        (bool success, ) = who.call{ value: amount }("");
        // if transfer reverts, send them WETH
        if (!success) {
            IWETH(weth).deposit{value: amount}();
            IWETH(weth).transfer(who, IWETH(weth).balanceOf(address(this)));
        }
    }

}