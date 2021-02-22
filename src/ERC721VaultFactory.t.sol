//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";

import "./ERC721VaultFactory.sol";
import "./test/TestERC721.sol";

interface Hevm {
    function warp(uint256) external;

    function roll(uint256) external;

    function store(
        address,
        bytes32,
        bytes32
    ) external;
}

contract User {

    VaultFactory public factory;

    constructor(address _factory) {
        factory = VaultFactory(_factory);
    }
    
    function call_updateGov(address payable _guy) public {
        factory.updateGov(_guy);
    }

    // depositing WETH and minting
    function call_acceptGov() public {
        factory.acceptGov();
    }
    
    function call_setFee(uint256 _fee) public {
        factory.setFee(_fee);
    }

    // to be able to receive funds
    receive() external payable {} // solhint-disable-line no-empty-blocks
}

/// @author Nibble Market
/// @title Tests for the vault factory
contract VaultFactoryTest is DSTest {
    Hevm public hevm;
    
    VaultFactory public factory;
    TestERC721 public token;

    User public user1;
    User public user2;
    User public user3;

    function setUp() public {
        // hevm "cheatcode", see: https://github.com/dapphub/dapptools/tree/master/src/hevm#cheat-codes
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        factory = new VaultFactory();

        token = new TestERC721();

        token.mint(address(this), 1);

        // create 3 users and provide funds through HEVM store
        user1 = new User(address(factory));
        user2 = new User(address(factory));
        user3 = new User(address(factory));
    }

    function test_updateGov() public {
        factory.updateGov(payable(address(user1)));
        user1.call_acceptGov();

        assertTrue(address(user1) == factory.gov());
    }

    function testFail_updateGov() public {
        user1.call_updateGov(payable(address(user2)));
    }

    function testFail_acceptGov() public {
        factory.updateGov(payable(address(user1)));
        user2.call_acceptGov();
    }

    function test_setFee() public {
        factory.setFee(50);
        assertEq(factory.fee(), 50);
    }

    function testFail_setFee() public {
        factory.setFee(150);
    }

    function testFail_setFee2() public {
        user1.call_setFee(50);
    }
}