// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {SrcDstChainScenario} from "./SrcDstChainScenario.sol";
import {BridgeParams, RouterActions} from "./RouterActions.sol";

contract AliceAndBobScenario is SrcDstChainScenario, RouterActions {
    address alice = address(0xa11ce);
    address bob = address(0xb0b);

    uint64 public constant BRIDGE_ONLY_GAS = 200000;

    function sendAliceToBobAndReceive(
        uint amount,
        bool deliverEth
    ) public returns (uint fees) {
        return
            sendAliceToTargetAndReceive(
                amount,
                deliverEth,
                bob,
                BRIDGE_ONLY_GAS,
                ""
            );
    }

    function sendAliceToBob(
        uint amount,
        bool deliverEth
    ) public returns (uint fees) {
        (, , fees) = sendAliceToTarget(
            amount,
            deliverEth,
            bob,
            BRIDGE_ONLY_GAS,
            ""
        );
    }

    function sendAliceToBobDeliverEth(uint amount) public returns (uint fees) {
        return sendAliceToBob(amount, true);
    }

    function sendAliceToBobDeliverWeth(uint amount) public returns (uint fees) {
        return sendAliceToBob(amount, false);
    }

    function sendAliceToBobAndReceiveDeliverEth(
        uint amount
    ) public returns (uint fees) {
        return sendAliceToBobAndReceive(amount, true);
    }

    function sendAliceToBobAndReceiveDeliverWeth(
        uint amount
    ) public returns (uint fees) {
        return sendAliceToBobAndReceive(amount, false);
    }

    function sendAliceToTarget(
        uint amount,
        bool deliverEth,
        address target,
        uint64 dstGasForCall,
        bytes memory payload
    ) public returns (BridgeParams memory params, uint8 msgType, uint fees) {
        params = BridgeParams({
            src: srcChain,
            dst: dstChain,
            fromAddress: alice,
            toAddress: target,
            amount: amount
        });
        msgType = payload.length == 0
            ? MT_ETH_TRANSFER
            : MT_ETH_TRANSFER_WITH_PAYLOAD;
        fees = attemptBridge(
            params,
            msgType,
            deliverEth,
            dstGasForCall,
            payload
        );
    }

    function sendAliceToTargetAndReceive(
        uint amount,
        bool deliverEth,
        address target,
        uint64 dstGasForCall,
        bytes memory payload
    ) public returns (uint fees) {
        startRecordingLzMessages();
        (
            BridgeParams memory params,
            uint8 msgType,
            uint _fees
        ) = sendAliceToTarget(
                amount,
                deliverEth,
                target,
                dstGasForCall,
                payload
            );
        fees = _fees;
        deliverLzMessageAtDestination(params.src, params.dst, dstGasForCall);
    }
}
