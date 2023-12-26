// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {DecentBridgeDeploymentSetup} from "./DecentBridgeDeploymentSetup.sol";

contract SrcDstChainScenario is DecentBridgeDeploymentSetup {
    string srcChain;
    string dstChain;

    function deploySrcDst() public {
        deployDecentBridgeRouterAndDecentEth(srcChain);
        registerDecentEth(srcChain);
        deployDecentBridgeRouterAndDecentEth(dstChain);
        registerDecentEth(dstChain);
        wireUp(srcChain, dstChain);
    }
}
