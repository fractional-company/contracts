//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OpenZeppelin/access/Ownable.sol";
import "./Interfaces/ISettings.sol";

contract Settings is Ownable, ISettings {

    /// @notice the maximum auction length
    uint256 public override maxAuctionLength;

    /// @notice the longest an auction can ever be
    uint256 public constant maxMaxAuctionLength = 8 weeks;

    /// @notice the minimum auction length
    uint256 public override minAuctionLength;

    /// @notice the shortest an auction can ever be
    uint256 public constant minMinAuctionLength = 1 days;

    /// @notice governance fee max
    uint256 public override governanceFee;

    /// @notice 10% fee is max
    uint256 public constant maxGovFee = 100;

    /// @notice max curator fee
    uint256 public override maxCuratorFee;

    /// @notice the % bid increase required for a new bid
    uint256 public override minBidIncrease;

    /// @notice 10% bid increase is max 
    uint256 public constant maxMinBidIncrease = 100;

    /// @notice 1% bid increase is min
    uint256 public constant minMinBidIncrease = 10;

    /// @notice the max % increase over the initial 
    uint256 public override maxReserveFactor;

    /// @notice the max % decrease from the initial
    uint256 public override minReserveFactor;

    /// @notice the address who receives auction fees
    address payable public override feeReceiver;

    /// @notice the list of NFTs allowed to be minted against
    mapping(address => bool) public override allowedNFTs;

    event UpdateMaxAuctionLength(uint256 _old, uint256 _new);

    event UpdateMinAuctionLength(uint256 _old, uint256 _new);

    event UpdateGovernanceFee(uint256 _old, uint256 _new);

    event UpdateCuratorFee(uint256 _old, uint256 _new);

    event UpdateMinBidIncrease(uint256 _old, uint256 _new);

    event UpdateMaxReserveFactor(uint256 _old, uint256 _new);

    event UpdateMinReserveFactor(uint256 _old, uint256 _new);

    event UpdateFeeReceiver(address _old, address _new);

    event UpdateAllowedNFT(address _nft, bool _allowed);

    constructor() {
        maxAuctionLength = 2 weeks;
        minAuctionLength = 3 days;
        feeReceiver = payable(msg.sender);
        minReserveFactor = 200;  // 20%
        maxReserveFactor = 5000; // 500%
        minBidIncrease = 50;     // 5%
        maxCuratorFee = 100;
    }

    function setMaxAuctionLength(uint256 _length) external onlyOwner {
        require(_length <= maxMaxAuctionLength, "max auction length too high");
        require(_length > minAuctionLength, "max auction length too low");

        emit UpdateMaxAuctionLength(maxAuctionLength, _length);

        maxAuctionLength = _length;
    }

    function setMinAuctionLength(uint256 _length) external onlyOwner {
        require(_length >= minMinAuctionLength, "min auction length too low");
        require(_length < maxAuctionLength, "min auction length too high");

        emit UpdateMinAuctionLength(minAuctionLength, _length);

        minAuctionLength = _length;
    }

    function setGovernanceFee(uint256 _fee) external onlyOwner {
        require(_fee <= maxGovFee, "fee too high");

        emit UpdateGovernanceFee(governanceFee, _fee);

        governanceFee = _fee;
    }

    function setMaxCuratorFee(uint256 _fee) external onlyOwner {
        emit UpdateCuratorFee(governanceFee, _fee);

        maxCuratorFee = _fee;
    }

    function setMinBidIncrease(uint256 _min) external onlyOwner {
        require(_min <= maxMinBidIncrease, "min bid increase too high");
        require(_min >= minMinBidIncrease, "min bid increase too low");

        emit UpdateMinBidIncrease(minBidIncrease, _min);

        minBidIncrease = _min;
    }

    function setMaxReserveFactor(uint256 _factor) external onlyOwner {
        require(_factor > minReserveFactor, "max reserve factor too low");

        emit UpdateMaxReserveFactor(maxReserveFactor, _factor);

        maxReserveFactor = _factor;
    }

    function setMinReserveFactor(uint256 _factor) external onlyOwner {
        require(_factor < maxReserveFactor, "min reserve factor too high");

        emit UpdateMinReserveFactor(minReserveFactor, _factor);

        minReserveFactor = _factor;
    }

    function setFeeReceiver(address payable _receiver) external onlyOwner {
        require(_receiver != address(0), "fees cannot go to 0 address");

        emit UpdateFeeReceiver(feeReceiver, _receiver);

        feeReceiver = _receiver;
    }

    function addAllowedNFT(address _nft) external onlyOwner {
        allowedNFTs[_nft] = true;

        emit UpdateAllowedNFT(_nft, true);
    }

    function removeAllowedNFT(address _nft) external onlyOwner {
        allowedNFTs[_nft] = false;

        emit UpdateAllowedNFT(_nft, false);
    }

}