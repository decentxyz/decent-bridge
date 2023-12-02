// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {DeployedAndReadyTestScenario} from "./DeployedAndReadyTestScenario.sol";


contract EthChain2WethChainScenario is DeployedAndReadyTestScenario {
    function setUp() public virtual override {
        srcChain = "arbitrum";
        dstChain = "avalanche";
        super.setUp();
    }
}
