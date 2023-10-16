// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {CommonBase} from "forge-std/Base.sol";
import {DecentEthRouter} from "src/DecentEthRouter.sol";
import {DcntEth} from "src/DcntEth.sol";
import {DeploymentHelpers} from "./DeploymentHelpers.sol";
import {DeployedContext} from "./DeployedContext.sol";

contract BridgeEth is Script, DeploymentHelpers, DeployedContext {
    uint64 DST_GAS_FOR_CALL = 120000;
    address me = 0xfD92d36aADf0103b5b012d6a8013FBf9857d27Ef;

    function run() public {
        vm.createSelectFork(srcChainAlias);
        vm.startBroadcast();
        bytes memory payload = abi.encode(me);
        uint amountToBridge = 10;
        (uint nativeFee, uint zroFee) = srcRouter.estimateSendAndCallFee(
            dstLzId,
            me, // us maybe inshallah?
            amountToBridge,
            DST_GAS_FOR_CALL,
            payload
        );
        uint totalFee = nativeFee + zroFee;
        console2.log("native fee", nativeFee, "zroFee", zroFee);
        srcRouter.bridgeEth{value: amountToBridge + totalFee}(
            dstLzId,
            me, // us
            amountToBridge,
            DST_GAS_FOR_CALL,
            payload
        );

        vm.stopBroadcast();
    }
}

contract BridgeFtmToSepolia is BridgeEth {
    constructor() {
        uint16 SEPOLIA_LZ_ID = 10161;
        srcChainAlias = "ftm-testnet";
        srcChainId = "4002";
        dstChainId = "11155111";
        dstLzId = SEPOLIA_LZ_ID;
    }
}
