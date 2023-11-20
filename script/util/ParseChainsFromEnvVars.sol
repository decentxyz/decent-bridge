// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {StringUtilities} from "../../test/common/Utils/StringUtilities.sol";
import {BroadcastMultichainSetup} from "./BroadcastMultichainSetup.sol";

contract ParseChainsFromEnvVars is
    Script,
BroadcastMultichainSetup,
    StringUtilities
{

    function getChains() public view returns (string[] memory) {
        string memory chainsStr = vm.envString("chains");
        string[] memory chains = split(chainsStr, ",");
        if (chains.length == 0) {
            revert("no chains passed");
        }
        return chains;
    }
}
