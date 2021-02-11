pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./NibbleCore.sol";

contract NibbleCoreTest is DSTest {
    NibbleCore core;

    function setUp() public {
        core = new NibbleCore();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
