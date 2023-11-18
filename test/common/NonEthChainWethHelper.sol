// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {BaseChainSetup} from "./BaseChainSetup.sol";

contract NonEthChainWethHelper is BaseChainSetup {
    mapping(string => address) wethWhaleLookup;

    function setupWhaleInfo() public {
        wethWhaleLookup["avalanche"] = address(
            0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8
        );
        wethWhaleLookup["polygon"] = address(
            0x28424507fefb6f7f8E9D3860F56504E4e5f5f390
        );
    }

    function mintWethTo(
        string memory chain,
        address to,
        uint256 amount
    ) public {
        switchTo(chain);
        address whale = wethWhaleLookup[chain];
        startImpersonating(whale);
        ERC20(wethLookup[chain]).transfer(to, amount);
        stopImpersonating();
    }
}
