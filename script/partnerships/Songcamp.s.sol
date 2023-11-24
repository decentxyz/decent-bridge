// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {AllChainsInfo} from "../../test/common/AllChainsInfo.sol";
import "./C4TEST.sol";

contract Songcamp is Script, AllChainsInfo, C4TEST {
    function setUp() public {
        setRuntime(ENV_FORK);
        setupChainInfo();
    }

    function run() public {
        C4TEST nft;
        string memory chain = vm.envString("chain");
        switchTo(chain);
        nft = new C4TEST();
        nft.toggleSaleEnabled();
    }
}
