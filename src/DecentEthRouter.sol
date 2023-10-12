// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WETH} from "solmate/tokens/WETH.sol";

contract DecentEthRouter {
    WETH weth;

    constructor(address payable wethAddress) {
        weth = WETH(wethAddress);

    }
}
