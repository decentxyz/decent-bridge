// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/console2.sol";
import "solidity-examples/token/oft/v2/OFTV2.sol";

contract OFTV2Mock is OFTV2 {
    constructor(address _layerZeroEndpoint, uint _initialSupply, uint8 _sharedDecimals) OFTV2("ExampleOFT", "OFT", _sharedDecimals, _layerZeroEndpoint) {
        _mint(_msgSender(), _initialSupply);
    }
}

contract OFTSample {
    constructor() {
        //console2.log("deploying new OFT contract");
        console2.log("my address is", address(this));
        //OFTV2 oft = new OFTV2("ExampleOFT", "OFT", 2, address(0));
        //console2.log("deployed new contract at", address(oft));
    }
}
