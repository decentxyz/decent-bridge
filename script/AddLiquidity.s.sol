// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {DecentEthRouter} from "src/DecentEthRouter.sol";
import {DcntEth} from "src/DcntEth.sol";
import {DeploymentHelpers} from "./DeploymentHelpers.sol";
import {DeployedChainContext} from "./DeployedChainContext.sol";
import {BridgedWeth} from "./BridgeEth.s.sol";

contract AddLiquidity is Script, DeploymentHelpers, DeployedChainContext {
    // to be read from env vars
    uint liquidity;
    bool isMainnet;

    constructor() {
        chainAlias = vm.envString("CHAIN");
        chainId = vm.envString("CHAIN_ID");
        liquidity = vm.envUint("LIQUIDITY");
        isMainnet = vm.envBool("MAINNET");
        console2.log("chain", chainAlias);
        console2.log("chainId", chainId);
        console2.log("liquidity", liquidity);
        console2.log("isMainnet", isMainnet);
    }

    function run() public {
        vm.createSelectFork(chainAlias);
        vm.startBroadcast();

        bool isGasEth = router.gasCurrencyIsEth();

        if (!isGasEth && !isMainnet) {
            BridgedWeth bridgedWeth = BridgedWeth(address(router.weth()));
            bridgedWeth.mint(address(msg.sender), liquidity);
            bridgedWeth.approve(address(router), liquidity);
        }

        if (isGasEth) {
            router.addLiquidityEth{value: liquidity}();
        } else {
            router.addLiquidityWeth(liquidity);
        }

        vm.stopBroadcast();
    }
}
