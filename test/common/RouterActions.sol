// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {DecentEthRouter} from "../../src/DecentEthRouter.sol";

import {WETH} from "solmate/tokens/WETH.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {RouterDeploymentSetup} from "./RouterDeploymentSetup.sol";
import {OpenDcntEth} from "./OpenDcntEth.sol";
import {MockEndpoint} from "./Endpoint.sol";

struct BridgeParams {
    string src;
    string dst;
    address fromAddress;
    address toAddress;
    uint amount;
}

contract RouterActions is RouterDeploymentSetup {
    uint8 public constant MT_ETH_TRANSFER = 0;
    uint8 public constant MT_ETH_TRANSFER_WITH_PAYLOAD = 1;

    function addLiquidity(string memory chain, uint amount) public {
        switchTo(chain);
        DecentEthRouter router = routerLookup[chain];
        if (gasEthLookup[chain]) {
            router.addLiquidityEth{value: amount}();
        } else {
            ERC20 weth = ERC20(wethLookup[chain]);
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
                params.amount,
                dstGasForCall,
                deliverEth
            );
        } else {
            srcRouter.bridgeWithPayload{value: value}(
                lzIdLookup[params.dst],
                params.toAddress,
                params.amount,
                deliverEth,
                dstGasForCall,
                payload
            );
        }
        stopImpersonating();
    }

    function receiveOFT(
        BridgeParams memory params,
        uint8 msgType,
        bool deliverEth,
        uint64 dstGasForCall,
        bytes memory payload
    ) public {
        switchTo(params.src);
        bytes memory oftPayload;
        if (msgType == MT_ETH_TRANSFER) {
            oftPayload = abi.encode(
                msgType,
                params.fromAddress,
                params.toAddress,
                deliverEth
            );
        } else {
            oftPayload = abi.encode(
                msgType,
                params.fromAddress,
                params.toAddress,
                deliverEth,
                payload
            );
        }

        bytes memory lzPayload = OpenDcntEth(address(dcntEthLookup[params.src]))
            .encodeSendAndCallPayload(
                address(routerLookup[params.src]), // first router (has decent eth)
                address(routerLookup[params.dst]), // to address (has decent eth)
                params.amount,
                oftPayload, // will have the recipients address
                dstGasForCall
            );

        switchTo(params.dst);
        MockEndpoint dstEndpoint = lzEndpointLookup[params.dst];

        address srcDcnEth = address(dcntEthLookup[params.src]);
        address dstDcnEth = address(dcntEthLookup[params.dst]);

        uint64 nonce = dstEndpoint.getInboundNonce(
            lzIdLookup[params.src],
            abi.encode(srcDcnEth, dstDcnEth)
        );

        address defaultLibAddress = dstEndpoint.defaultReceiveLibraryAddress();

        startImpersonating(defaultLibAddress);
        dstEndpoint.receivePayload(
            lzIdLookup[params.src], // src chain id
            abi.encodePacked(srcDcnEth, dstDcnEth), // src address
            dstDcnEth, // dst address
            nonce + 1, // nonce
            dstGasForCall, // gas limit
            lzPayload // payload
        );

        stopImpersonating();
    }

    // test scenarios

    // attemptBridgeEth // deliver eth is true
    //      attemptBridgeEth to eth chain ?  should deliver eth
    //      attemptBridgeEth to weth chain ?  should deliver weth

    // attemptBridgeWeth // deliver eth is false
    //      attemptBridgeWeth to eth chain ?  should deliver weth
    //      attemptBridgeWeth to weth chain ?  should deliver weth

    // attemptBridgeEthWithPayload // deliver
    //      attemptBridgeEthWithPayload to eth chain? should deliver eth & call
    //      attemptBridgeEthWithPayload to weth chain? should deliver weth & call

    // attemptBridgeWithPayload
    //      attemptBridgeWithPayload to eth chain? should deliver weth & call
    //      attemptBridgeWithPayload to weth chain? should deliver weth & call
}
