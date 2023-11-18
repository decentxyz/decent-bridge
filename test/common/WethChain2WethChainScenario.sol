// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {DeployedAndReadyTestScenario} from "./DeployedAndReadyScenario.sol";

contract WethChain2WethChainScenario is DeployedAndReadyTestScenario {
    function setUp() public virtual override {
        srcChain = "avalanche";
        dstChain = "polygon";
        super.setUp();
    }
}
