// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {BridgeParams} from "./common/RouterActions.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import {DecentEthRouter} from "../src/DecentEthRouter.sol";
import {EthChain2EthChainScenario} from "./common/EthChain2EthChainScenario.sol";

contract AuditTests is EthChain2EthChainScenario {
    function testArbitraryCallDataShouldNotBeAbleToDrainWeth() public {
        dealTo(srcChain, alice, 0.1 ether);
        DecentEthRouter router = routerLookup[srcChain];
        uint64 drainGas = 5e5;

        bytes memory payload = abi.encodeCall(
            ERC20.transfer,
            (bob, AVAILABLE_LIQUIDITY - 1 ether)
        );

        uint amount = 0.0069 ether;

        sendAliceToTargetAndReceive(
            amount,
            false,
            wethLookup[dstChain],
            drainGas,
            payload
        );

        assertWethBalanceEq(dstChain, alice, amount);
        assertWethBalanceEq(dstChain, bob, 0);
    }
}
