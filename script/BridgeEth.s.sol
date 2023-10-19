// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {CommonBase} from "forge-std/Base.sol";
import {DecentEthRouter} from "src/DecentEthRouter.sol";
import {DcntEth} from "src/DcntEth.sol";
import {DeploymentHelpers} from "./DeploymentHelpers.sol";
import {DeployedContext} from "./DeployedContext.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract BridgedWeth is ERC20("Wrapped Ether", "WETH", 18) {
    function mint(address to, uint amount) external {
        _mint(to, amount);
    }
}

contract BridgeEth is Script, DeploymentHelpers, DeployedContext {
    bool srcChainGasIsEth;
    uint64 DST_GAS_FOR_CALL = 120000;

    function run() public {
        vm.createSelectFork(srcChainAlias);
        vm.startBroadcast();
        address me = msg.sender;
        uint amountToBridge = 10;
        if (!srcChainGasIsEth) {
            BridgedWeth weth = BridgedWeth(address(srcRouter.weth()));
            weth.mint(address(this), amountToBridge);
            weth.approve(address(srcRouter), amountToBridge);
        }
        (uint nativeFee, uint zroFee) = srcRouter.estimateSendAndCallFee(
            dstLzId,
            me, // us maybe inshallah?
            amountToBridge,
            DST_GAS_FOR_CALL
        );
        uint totalFee = nativeFee + zroFee;
        uint value;
        if (srcChainGasIsEth) {
            value = amountToBridge + totalFee;
        } else {
            value = totalFee;
        }
        console2.log("native fee", nativeFee, "zroFee", zroFee);
        srcRouter.bridgeEth{value: value}(
            dstLzId,
            me, // us
            amountToBridge,
            DST_GAS_FOR_CALL
        );

        vm.stopBroadcast();
    }
}

contract BridgeSepoliaToFtm is BridgeEth {
    constructor() {
        srcChainGasIsEth = true;
        uint16 FTM_LZ_ID = 10112;
        srcChainAlias = "sepolia";
        srcChainId = "11155111";
        dstChainId = "4002";
        dstLzId = FTM_LZ_ID;
    }
}

contract BridgeFtmToSepolia is BridgeEth {
    constructor() {
        srcChainGasIsEth = false;
        uint16 SEPOLIA_LZ_ID = 10161;
        srcChainAlias = "ftm-testnet";
        srcChainId = "4002";
        dstChainId = "11155111";
        dstLzId = SEPOLIA_LZ_ID;
    }
}
