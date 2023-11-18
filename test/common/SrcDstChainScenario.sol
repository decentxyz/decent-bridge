// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {RouterDeploymentSetup} from "./RouterDeploymentSetup.sol";

contract SrcDstChainScenario is RouterDeploymentSetup {
    string srcChain;
    string dstChain;

    function deploySrcDst() public {
        deployRouter(srcChain);
        deployRouter(dstChain);
        wireUp(srcChain, dstChain);
    }
}
