// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {MockEndpoint} from "forge-toolkit/LzChainSetup.sol";
import {WethMintHelper} from "forge-toolkit/WethMintHelper.sol";
import {DecentEthRouter} from "../../src/DecentEthRouter.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {DecentBridgeDeploymentSetup} from "./DecentBridgeDeploymentSetup.sol";
import {console2} from "forge-std/console2.sol";

struct BridgeParams {
    string src;
    string dst;
    address fromAddress;
    address toAddress;
    uint amount;
}

contract RouterActions is DecentBridgeDeploymentSetup, WethMintHelper {
    uint8 public constant MT_ETH_TRANSFER = 0;
    uint8 public constant MT_ETH_TRANSFER_WITH_PAYLOAD = 1;

    function removeLiquidity(string memory chain, uint amount) public {
        switchTo(chain);
        DecentEthRouter router = routerLookup[chain];
        if (gasEthLookup[chain]) {
            router.removeLiquidityEth(amount);
        } else {
            router.removeLiquidityWeth(amount);
        }
    }

    function addLiquidity(string memory chain, uint amount) public {
        switchTo(chain);
        DecentEthRouter router = routerLookup[chain];
        if (gasEthLookup[chain]) {
            router.addLiquidityEth{value: amount}();
        } else {
            ERC20 weth = ERC20(getWeth(chain));
            if (isForgeTest()) {
                mintWethTo(chain, address(this), amount);
            } else {
                mintWethTo(chain, address(msg.sender), amount);
            }
            weth.approve(address(router), amount);
            router.addLiquidityWeth(amount);
        }
    }

    function attemptBridge(
        BridgeParams memory params,
        uint8 msgType,
        bool deliverEth,
        uint64 dstGasForCall,
        bytes memory payload
    ) internal returns (uint fees) {
        switchTo(params.src);
        DecentEthRouter srcRouter = routerLookup[params.src];
        startImpersonating(params.fromAddress);
        (uint nativeFee, uint zroFee) = srcRouter.estimateSendAndCallFee(
            msgType,
            lzIdLookup[params.dst],
            params.toAddress,
            params.fromAddress,
            params.amount,
            dstGasForCall,
            deliverEth,
            payload
        );

        uint value = nativeFee + zroFee;
        fees = nativeFee + zroFee;
        if (gasEthLookup[params.src]) {
            value += params.amount;
        } else {
            WETH(payable(wethLookup[params.src])).approve(
                address(srcRouter),
                params.amount
            );
        }

        if (msgType == MT_ETH_TRANSFER) {
            srcRouter.bridge{value: value}(
                lzIdLookup[params.dst],
                params.toAddress,
                params.fromAddress,
                params.amount,
                dstGasForCall,
                deliverEth
            );
        } else {
            srcRouter.bridgeWithPayload{value: value}(
                lzIdLookup[params.dst],
                params.toAddress,
                params.fromAddress,
                params.amount,
                deliverEth,
                dstGasForCall,
                payload
            );
        }
        stopImpersonating();
    }
}
