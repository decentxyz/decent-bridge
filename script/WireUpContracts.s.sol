// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {DecentEthRouter} from "src/DecentEthRouter.sol";
import {DcntEth} from "src/DcntEth.sol";
import {DeploymentHelpers} from "./DeploymentHelpers.sol";
import {DeployedSrcDstContext} from "./DeployedSrcDstContext.sol";

contract WireUp is Script, DeploymentHelpers, DeployedSrcDstContext {
    function run() public {
        uint chainFork = vm.createSelectFork(srcChainAlias);
        vm.startBroadcast();
        srcRouter.addDestinationBridge(
            dstLzId,
            address(dstRouter), // you're sending to this
            address(dstDcntEth), // this is who you're approving
            MIN_DST_GAS
        );
        vm.stopBroadcast();
    }
}

contract WireUpContracts is WireUp {
    constructor() {
        srcChainAlias = vm.envString("SRC_CHAIN");
        srcChainId = vm.envString("SRC_CHAIN_ID");
        dstChainId = vm.envString("DST_CHAIN_ID");
        dstLzId = uint16(vm.envUint("DST_CHAIN_LZ_ID"));
    }
}
