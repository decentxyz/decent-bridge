// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {TestMultichainSetup} from "./common/TestMultichainSetup.sol";

contract GasReport is Test, TestMultichainSetup {
    function testDeployAndWireUp() public {
        setRuntime("mainnet");
        string[] memory chains = new string[](3);
        chains[0] = "optimism";
        chains[1] = "zora";
        chains[2] = "arbitrum";
        deploy(chains);
        wireUp(chains);
    }
}
