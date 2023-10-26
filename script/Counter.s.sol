// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/Counter.sol";

contract CounterScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("TESTNET_ACCOUNT");
        vm.startBroadcast(deployerPrivateKey);
        new Counter();
        vm.stopBroadcast();
    }
}
