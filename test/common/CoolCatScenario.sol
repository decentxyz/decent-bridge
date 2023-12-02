// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {BaseChainSetup} from "arshans-forge-toolkit/BaseChainSetup.sol";
import {SrcDstChainScenario} from "./SrcDstChainScenario.sol";
import {CoolCat} from "./CoolCat.sol";

contract CoolCatScenario is BaseChainSetup, SrcDstChainScenario {
    uint64 GAS_FOR_MEOW_MEOW = 500000;

    function birthCoolCat() internal returns (CoolCat) {
        switchTo(dstChain);
        return new CoolCat(payable(wethLookup[dstChain]));
    }
}
