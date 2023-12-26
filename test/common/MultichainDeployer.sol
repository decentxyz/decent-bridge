// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {console2} from "forge-std/console2.sol";
import {DecentBridgeDeploymentSetup} from "./DecentBridgeDeploymentSetup.sol";

contract MultichainDeployer is DecentBridgeDeploymentSetup {
    function wireUp(string[] memory chains) internal {
        for (uint i = 0; i < chains.length; i++) {
            string memory srcChain = chains[i];
            for (uint j = i + 1; j < chains.length; j++) {
                string memory dstChain = chains[j];
                wireUp(srcChain, dstChain);
            }
        }
    }

    function deploy(string[] memory chains) internal {
        for (uint i = 0; i < chains.length; i++) {
            string memory chain = chains[i];
            deployDecentBridgeRouterAndDecentEth(chain);
            registerDecentEth(chain);
        }
    }
}
