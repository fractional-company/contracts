// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "../src/ERC721VaultFactory.sol";

contract V1ERC20Deploy is Script {
    ERC721VaultFactory public factory;
    Settings public settings;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        settings = new Settings();
        factory = new ERC721VaultFactory(address(settings));

        vm.stopBroadcast();
    }
}
