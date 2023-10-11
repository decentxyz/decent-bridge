// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/console2.sol";
import "lz-contracts/token/oft/v2/OFTV2.sol" as OFTV2;

contract OFTSample {
    constructor() {
        console2.log("deploying new OFT contract");
        OFTV2 oft = new OFTV2("ExampleOFT", "OFT", 2, address(0));
        console2.log("deployed new contract at", address(oft));

    }
}
