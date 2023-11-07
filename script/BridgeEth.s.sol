// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {CommonBase} from "forge-std/Base.sol";
import {DecentEthRouter} from "src/DecentEthRouter.sol";
import {DcntEth} from "src/DcntEth.sol";
import {DeploymentHelpers} from "./DeploymentHelpers.sol";
import {DeployedSrcDstContext} from "./DeployedSrcDstContext.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract BridgedWeth is ERC20("Wrapped Ether", "WETH", 18) {
    function mint(address to, uint amount) external {
        _mint(to, amount);
    }
}

contract BridgeEth is Script, DeploymentHelpers, DeployedSrcDstContext {
    uint64 DST_GAS_FOR_CALL = 120000;
    bool isMainnet;

    constructor() {
        dstLzId = uint16(vm.envUint("DST_CHAIN_LZ_ID"));
        srcChainAlias = vm.envString("SRC_CHAIN");
        srcChainId = vm.envString("SRC_CHAIN_ID");
        dstChainId = vm.envString("DST_CHAIN_ID");
        isMainnet = vm.envBool("MAINNET");
    }

    function run() public {
        vm.createSelectFork(srcChainAlias);
        vm.startBroadcast();
        address me = msg.sender;
        uint amountToBridge = vm.envUint("AMOUNT");

        bool srcChainGasIsEth = srcRouter.gasCurrencyIsEth();
        BridgedWeth weth = BridgedWeth(address(srcRouter.weth()));
        if (!srcChainGasIsEth && !isMainnet) {
            console2.log("approving");
            weth.mint(me, amountToBridge);
        }
        weth.approve(address(srcRouter), amountToBridge);
        (uint nativeFee, uint zroFee) = srcRouter.estimateSendAndCallFee(
            MT_ETH_TRANSFER,
            dstLzId,
            me, // us maybe inshallah?
            amountToBridge,
            DST_GAS_FOR_CALL,
            ""
        );
        uint totalFee = nativeFee + zroFee;
        uint value;
        if (srcChainGasIsEth) {
            value = amountToBridge + totalFee;
        } else {
            value = totalFee;
        }
        console2.log("native fee", nativeFee, "zroFee", zroFee);
        if (srcRouter.gasCurrencyIsEth()) {
            srcRouter.bridgeEth{value: value}(
                dstLzId,
                me, // us
                amountToBridge,
                DST_GAS_FOR_CALL
            );
        } else {
            srcRouter.bridgeWeth{value: value}(
                dstLzId,
                me, // us
                amountToBridge,
                DST_GAS_FOR_CALL
            );
        }

        vm.stopBroadcast();
    }
}
