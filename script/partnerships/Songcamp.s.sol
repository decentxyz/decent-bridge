// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {AllChainsInfo} from "../../test/common/AllChainsInfo.sol";
import "./C4TEST.sol";

contract Songcamp is Script, AllChainsInfo, C4TEST {
    function setUp() public {
        if (vm.envOr("TESTNET", false)) {
            setRuntime(ENV_TESTNET);
        } else if (vm.envOr("MAINNET", false)) {
            setRuntime(ENV_MAINNET);
        } else {
            setRuntime(ENV_FORK);
        }
        setupChainInfo();
    }

    function run() public {
        C4TEST nft;
        string memory chain = vm.envString("chain");
        switchTo(chain);
        nft = new C4TEST();
        nft.toggleSaleEnabled();
        C4TEST(0xd643567B131777cD52841Ca1FF7663Ba890a0092).setMintPrice(0.00001 ether);
    }
}
