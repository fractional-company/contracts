//SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./Interfaces/IWETH.sol";

import "./OpenZeppelin/token/ERC721/IERC721.sol";

import "./Settings.sol";
import "./VaultStorage.sol";

contract VaultLogic is VaultStorage {
    /// ------------------------
    /// -------- EVENTS --------
    /// ------------------------

    /// @notice An event emitted when a user updates their price
    event PriceUpdate(address indexed user, uint price);

    /// @notice An event emitted when an auction starts
    event Start(address indexed buyer, uint price);

    /// @notice An event emitted when a bid is made
    event Bid(address indexed buyer, uint price);

    /// @notice An event emitted when an auction is won
    event Won(address indexed buyer, uint price);

    /// @notice An event emitted when someone redeems all tokens for the NFT
    event Redeem(address indexed redeemer);

    /// @notice An event emitted when someone cashes in ERC20 tokens for ETH from an ERC721 token sale
    event Cash(address indexed owner, uint256 shares);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /// --------------------------------
    /// -------- VIEW FUNCTIONS --------
    /// --------------------------------

    function reservePrice() public view returns(uint256) {
        return votingTokens == 0 ? 0 : reserveTotal / votingTokens;
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

    /// @notice allow curator to update the auction length
    /// @param _length the new base price
    function updateAuctionLength(uint256 _length) external {
        require(msg.sender == curator, "update:not curator");
        require(_length >= ISettings(settings).minAuctionLength() && _length <= ISettings(settings).maxAuctionLength(), "update:invalid auction length");

        auctionLength = _length;
    }

    /// @notice allow the curator to change their fee
    /// @param _fee the new fee
    function updateFee(uint256 _fee) external {
        require(msg.sender == curator, "update:not curator");
        require(_fee <= ISettings(settings).maxCuratorFee(), "update:cannot increase fee this high");

        _claimFees();

        fee = _fee;
    }

    /// @notice external function to claim fees for the curator and governance
    function claimFees() external {
        _claimFees();
    }

    /// @dev interal fuction to calculate and mint fees
    function _claimFees() internal {
        require(auctionState != State.ended, "claim:cannot claim after auction ends");

        // get how much in fees the curator would make in a year
        uint256 currentAnnualFee = fee * totalSupply / 1000; 
        // get how much that is per second;
        uint256 feePerSecond = currentAnnualFee / 31536000;
        // get how many seconds they are eligible to claim
        uint256 sinceLastClaim = block.timestamp - lastClaimed;
        // get the amount of tokens to mint
        uint256 curatorMint = sinceLastClaim * feePerSecond;

        // now lets do the same for governance
        address govAddress = ISettings(settings).feeReceiver();
        uint256 govFee = ISettings(settings).governanceFee();
        currentAnnualFee = govFee * totalSupply / 1000; 
        feePerSecond = currentAnnualFee / 31536000;
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
        require(auctionState == State.inactive, "update:auction live cannot update price");
        uint256 old = userPrices[msg.sender];
        require(_new != old, "update:not an update");
        uint256 weight = balanceOf[msg.sender];

        if (votingTokens == 0) {
            votingTokens = weight;
            reserveTotal = weight * _new;
        }
        // they are the only one voting
        else if (weight == votingTokens && old != 0) {
            reserveTotal = weight * _new;
        }
        // previously they were not voting
        else if (old == 0) {
            uint256 averageReserve = reserveTotal / votingTokens;

            uint256 reservePriceMin = averageReserve * ISettings(settings).minReserveFactor() / 1000;
            require(_new >= reservePriceMin, "update:reserve price too low");
            uint256 reservePriceMax = averageReserve * ISettings(settings).maxReserveFactor() / 1000;
            require(_new <= reservePriceMax, "update:reserve price too high");

            votingTokens += weight;
            reserveTotal += weight * _new;
        } 
        // they no longer want to vote
        else if (_new == 0) {
            votingTokens -= weight;
            reserveTotal -= weight * old;
        } 
        // they are updating their vote
        else {
            uint256 averageReserve = (reserveTotal - (old * weight)) / (votingTokens - weight);

            uint256 reservePriceMin = averageReserve * ISettings(settings).minReserveFactor() / 1000;
            require(_new >= reservePriceMin, "update:reserve price too low");
            uint256 reservePriceMax = averageReserve * ISettings(settings).maxReserveFactor() / 1000;
            require(_new <= reservePriceMax, "update:reserve price too high");

            reserveTotal = reserveTotal + (weight * _new) - (weight * old);
        }

        userPrices[msg.sender] = _new;

        emit PriceUpdate(msg.sender, _new);
    }

    /// @notice an internal function used to update sender and receivers price on token transfer
    /// @param _from the ERC20 token sender
    /// @param _to the ERC20 token receiver
    /// @param _amount the ERC20 token amount
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal {
        if (_from != address(0) && auctionState == State.inactive) {
            uint256 fromPrice = userPrices[_from];
            uint256 toPrice = userPrices[_to];

            // only do something if users have different reserve price
            if (toPrice != fromPrice) {
                // new holder is not a voter
                if (toPrice == 0) {
                    // get the average reserve price ignoring the senders amount
                    votingTokens -= _amount;
                    reserveTotal -= _amount * fromPrice;
                }
                // old holder is not a voter
                else if (fromPrice == 0) {
                    votingTokens += _amount;
                    reserveTotal += _amount * toPrice;
                }
                // both holders are voters
                else {
                    reserveTotal = reserveTotal + (_amount * toPrice) - (_amount * fromPrice);
                }
            }
        }
    }

    /// @notice kick off an auction. Must send reservePrice in ETH
    function start() external payable {
        require(auctionState == State.inactive, "start:no auction starts");
        require(msg.value >= reservePrice(), "start:too low bid");
        require(votingTokens * 1000 >= ISettings(settings).minVotePercentage() * totalSupply, "start:not enough voters");
        
        auctionEnd = block.timestamp + auctionLength;
        auctionState = State.live;

        livePrice = msg.value;
        winning = payable(msg.sender);

        emit Start(msg.sender, msg.value);
    }

    /// @notice an external function to bid on purchasing the vaults NFT. The msg.value is the bid amount
    function bid() external payable {
        require(auctionState == State.live, "bid:auction is not live");
        uint256 increase = ISettings(settings).minBidIncrease() + 1000;
        require(msg.value * 1000 >= livePrice * increase, "bid:too low bid");
        require(block.timestamp < auctionEnd, "bid:auction ended");

        // If bid is within 15 minutes of auction end, extend auction
        if (auctionEnd - block.timestamp <= 15 minutes) {
            auctionEnd += 15 minutes;
        }

        _sendWETH(winning, livePrice);

        livePrice = msg.value;
        winning = payable(msg.sender);

        emit Bid(msg.sender, msg.value);
    }

    /// @notice an external function to end an auction after the timer has run out
    function end() external {
        require(auctionState == State.live, "end:vault has already closed");
        require(block.timestamp >= auctionEnd, "end:auction live");

        _claimFees();

        // transfer erc721 to winner
        IERC721(token).transferFrom(address(this), winning, id);

        auctionState = State.ended;

        emit Won(winning, livePrice);
    }

    /// @notice an external function to burn all ERC20 tokens to receive the ERC721 token
    function redeem() external {
        require(auctionState == State.inactive, "redeem:no redeeming");
        _burn(msg.sender, totalSupply);
        
        // transfer erc721 to redeemer
        IERC721(token).transferFrom(address(this), msg.sender, id);
        
        auctionState = State.redeemed;

        emit Redeem(msg.sender);
    }

    /// @notice an external function to burn ERC20 tokens to receive ETH from ERC721 token purchase
    function cash() external {
        require(auctionState == State.ended, "cash:vault not closed yet");
        uint256 bal = balanceOf[msg.sender];
        require(bal > 0, "cash:no tokens to cash out");
        uint256 share = bal * address(this).balance / totalSupply;
        _burn(msg.sender, bal);

        _sendWETH(payable(msg.sender), share);

        emit Cash(msg.sender, share);
    }

    /// @dev internal helper function to send ETH and WETH on failure
    function _sendWETH(address who, uint256 amount) internal {
        IWETH(weth).deposit{value: amount}();
        IWETH(weth).transfer(who, IWETH(weth).balanceOf(address(this)));
    }

    // ============ ERC20 Spec ============

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        _beforeTokenTransfer(from, to, value);
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        _transfer(from, to, value);
        return true;
    }

}