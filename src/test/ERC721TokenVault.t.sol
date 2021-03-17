//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";

import "../Settings.sol";
import "../ERC721VaultFactory.sol";
import "../ERC721TokenVault.sol";
import "./TestERC721.sol";

interface Hevm {
    function warp(uint256) external;

    function roll(uint256) external;

    function store(
        address,
        bytes32,
        bytes32
    ) external;
}

contract User is ERC721Holder {

    TokenVault public vault;

    constructor(address _vault) {
        vault = TokenVault(_vault);
    }
    
    function call_transfer(address _guy, uint256 _amount) public {
        vault.transfer(_guy, _amount);
    }

    function call_updatePrice(uint256 _price) public {
        vault.updateUserPrice(_price);
    }
    
    function call_bid(uint256 _amount) public {
        vault.bid{value: _amount}();
    }
    
    function call_start(uint256 _amount) public {
        vault.start{value: _amount}();
    }

    function call_cash() public {
        vault.cash();
    }

    // to be able to receive funds
    receive() external payable {} // solhint-disable-line no-empty-blocks
}

contract UserNoETH is ERC721Holder {

    bool public canReceive = true;

    TokenVault public vault;

    constructor(address _vault) {
        vault = TokenVault(_vault);
    }
    
    function call_transfer(address _guy, uint256 _amount) public {
        vault.transfer(_guy, _amount);
    }

    function call_updatePrice(uint256 _price) public {
        vault.updateUserPrice(_price);
    }
    
    function call_bid(uint256 _amount) public {
        vault.bid{value: _amount}();
    }
    
    function call_start(uint256 _amount) public {
        vault.start{value: _amount}();
    }

    function call_cash() public {
        vault.cash();
    }

    function setCanReceive(bool _can) public {
        canReceive = _can;
    }

    // to be able to receive funds
    receive() external payable {require(canReceive);} // solhint-disable-line no-empty-blocks
}


contract Curator {
    TokenVault public vault;

    constructor(address _vault) {
        vault = TokenVault(_vault);
    }

    function call_updateCurator(address _who) public {
        vault.updateCurator(_who);
    }

    function call_kickCurator(address _who) public {
        vault.kickCurator(_who);
    }

    // to be able to receive funds
    receive() external payable {} // solhint-disable-line no-empty-blocks
}

/// @author Nibble Market
/// @title Tests for the vaults
contract VaultTest is DSTest, ERC721Holder {
    Hevm public hevm;
    
    ERC721VaultFactory public factory;
    Settings public settings;
    TestERC721 public token;
    TokenVault public vault;

    User public user1;
    User public user2;
    User public user3;

    UserNoETH public user4;

    Curator public curator;

    function setUp() public {
        // hevm "cheatcode", see: https://github.com/dapphub/dapptools/tree/master/src/hevm#cheat-codes
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        settings = new Settings();

        settings.setGovernanceFee(10);

        factory = new ERC721VaultFactory(address(settings));

        token = new TestERC721();

        settings.addAllowedNFT(address(token));

        token.mint(address(this), 1);

        token.setApprovalForAll(address(factory), true);
        factory.mint("testName", "TEST", address(token), 1, 100e18, 1 ether, 50);

        vault = factory.vaults(0);

        // create a curator account
        curator = new Curator(address(factory));

        // create 3 users and provide funds through HEVM store
        user1 = new User(address(vault));
        user2 = new User(address(vault));
        user3 = new User(address(vault));
        user4 = new UserNoETH(address(vault));

        payable(address(user1)).transfer(10 ether);
        payable(address(user2)).transfer(10 ether);
        payable(address(user3)).transfer(10 ether);
        payable(address(user4)).transfer(10 ether);
    }

    /// -------------------------------
    /// -------- GOV FUNCTIONS --------
    /// -------------------------------

    function test_kickCurator() public {
        vault.updateCurator(address(curator));
        assertTrue(vault.curator() == address(curator));
        vault.kickCurator(address(this));
        assertTrue(vault.curator() == address(this));
    }

    function testFail_kickCurator() public {
        curator.call_kickCurator(address(curator));
    }

    /// -----------------------------------
    /// -------- CURATOR FUNCTIONS --------
    /// -----------------------------------

    function test_updateCurator() public {
        vault.updateCurator(address(curator));
        assertTrue(vault.curator() == address(curator));
    }

    function testFail_updateCurator() public {
        curator.call_updateCurator(address(curator));
    }

    function test_updateBasePrice() public {
        // current reserve price is 1 ETH
        // lets up base price to 10 ETH. After a transfer new reserve should be 2 ETH (20%)
        vault.updateBasePrice(10 ether);
        vault.transfer(address(user1), 50000000000000000000);
        assertEq(vault.reservePrice(), 2 ether);
    }

    function test_updateBasePrice2() public {
        // current reserve price is 1 ETH
        // lets up base price to 4 ETH. After a transfer new reserve should be 1 ETH
        vault.updateBasePrice(4 ether);
        vault.transfer(address(user1), 50000000000000000000);
        assertEq(vault.reservePrice(), 1 ether);
    }

    function test_updateBasePrice3() public {
        // current reserve price is 1 ETH
        // lets lower base price to 0.1 ETH. After a transfer new reserve should be 0.5 ETH
        vault.updateBasePrice(0.1 ether);
        vault.transfer(address(user1), 50000000000000000000);
        assertEq(vault.reservePrice(), 0.5 ether);
    }

    function test_updateBasePrice4() public {
        // current reserve price is 1 ETH
        // lets lower base price to 0.2 ETH. After a transfer new reserve should be 1 ETH
        vault.updateBasePrice(0.2 ether);
        vault.transfer(address(user1), 50000000000000000000);
        assertEq(vault.reservePrice(), 1 ether);
    }

    function test_updateAuctionLength() public {
        vault.updateAuctionLength(2 weeks);
        assertTrue(vault.auctionLength() == 2 weeks);
    }

    function testFail_updateAuctionLength() public {
        vault.updateAuctionLength(0.1 days);
    }

    function testFail_updateAuctionLength2() public {
        vault.updateAuctionLength(100 weeks);
    }

    function test_updateFee() public {
        vault.updateFee(100);
        assertEq(vault.fee(), 100);
    }

    function testFail_updateFee() public {
        vault.updateFee(101);
    }

    function test_claimFees() public {
        // curator fee is 5%
        // gov fee is 1%
        // we should increase total supply by 6%
        hevm.warp(block.timestamp + 31536000 seconds);
        vault.claimFees();
        assertTrue(vault.totalSupply() >= 105999999999900000000 && vault.totalSupply() < 106000000000000000000);
    }

    /// --------------------------------
    /// -------- CORE FUNCTIONS --------
    /// --------------------------------

    function test_initialReserve() public {
        assertEq(vault.reservePrice(), 1 ether);
    }

    function test_reservePriceTransfer() public {
        // reserve price here should not change
        vault.transfer(address(user1), 50000000000000000000);
        assertEq(vault.reservePrice(), 1 ether);

        assertEq(vault.userPrices(address(user1)), 1 ether);

        // reserve price should update to 1.5 ether
        user1.call_updatePrice(2 ether);
        assertEq(vault.reservePrice(), 1.5 ether);

        // now user 1 sends half their tokens to user 2
        // reserve price is 1 ether * 0.5 + 2 ether * 0.25 + 1.5 ether * 0.25
        user1.call_transfer(address(user2), 25000000000000000000);
        assertEq(vault.reservePrice(), 1.375 ether);

        // send all tokens back to first user
        // their reserve price is 1 ether and they hold all tokens
        user1.call_transfer(address(this), 25000000000000000000);
        user2.call_transfer(address(this), 25000000000000000000);
        assertEq(vault.reservePrice(), 1 ether);
    }

    function test_bid() public {
        vault.transfer(address(user1), 25000000000000000000);
        vault.transfer(address(user2), 25000000000000000000);
        vault.transfer(address(user3), 50000000000000000000);

        user1.call_start(1.05 ether);

        assertTrue(vault.auctionLive());

        uint256 bal = address(user1).balance;
        user2.call_bid(1.5 ether);
        assertEq(bal + 1.05 ether, address(user1).balance);
        bal = address(user2).balance;
        user1.call_bid(2 ether);
        assertEq(bal + 1.5 ether, address(user2).balance);

        hevm.warp(block.timestamp + 7 days);

        vault.end();

        assertEq(token.balanceOf(address(user1)), 1);

        // auction has ended. Now lets get all token holders their ETH
        // user1 gets 1/4 of 2 ETH or 0.5 ETH
        // user2 gets 1/4 of 2 ETH or 0.5 ETH
        // this gets 1/2 of 2 ETH or 1 ETH
        uint256 user1Bal = address(user1).balance;
        uint256 user2Bal = address(user2).balance;
        uint256 user3Bal = address(user3).balance;

        user1.call_cash();
        assertEq(user1Bal + 0.5 ether, address(user1).balance);
        user2.call_cash();
        assertEq(user2Bal + 0.5 ether, address(user2).balance);
        user3.call_cash();
        assertEq(user3Bal + 1 ether, address(user3).balance);

        assertTrue(!vault.auctionLive());
        assertTrue(vault.vaultClosed());
    }

    function test_redeem() public {
        vault.redeem();
        assertTrue(!vault.auctionLive());
        assertTrue(vault.vaultClosed());

        assertEq(token.balanceOf(address(this)), 1);
    }

    function test_cantGetEth() public {
        vault.transfer(address(user1), 25000000000000000000);
        vault.transfer(address(user2), 25000000000000000000);
        vault.transfer(address(user4), 50000000000000000000);

        user4.call_start(1.05 ether);
        user4.setCanReceive(false);
        assertTrue(vault.auctionLive());

        user2.call_bid(1.5 ether);
        uint256 wethBal = IWETH(vault.weth()).balanceOf(address(user4));
        assertEq(1.05 ether, wethBal);
    }

    receive() external payable {}
    
}