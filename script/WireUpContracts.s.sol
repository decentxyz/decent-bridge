// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {DecentEthRouter} from "src/DecentEthRouter.sol";
import {DcntEth} from "src/DcntEth.sol";
import {DeploymentHelpers} from "./DeploymentHelpers.sol";
import {DeployedContext} from "./DeployedContext.sol";

contract WireUp is Script, DeploymentHelpers, DeployedContext {
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

contract WireUpSepoliaToFtm is WireUp {
    constructor() {
        uint16 FTM_LZ_ID = 10112;
        srcChainAlias = "sepolia";
        srcChainId = "11155111";
        dstChainId = "4002";
        dstLzId = FTM_LZ_ID;
    }
}

contract WireUpFtmToSepolia is WireUp {
    constructor() {
        uint16 SEPOLIA_LZ_ID = 10161;
        srcChainAlias = "ftm-testnet";
        srcChainId = "4002";
        dstChainId = "11155111";
        dstLzId = SEPOLIA_LZ_ID;
    }
}
