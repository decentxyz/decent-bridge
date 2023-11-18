// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {DeployedAndReadyTestScenario} from "./DeployedAndReadyScenario.sol";

contract WethChain2EthChainScenario is DeployedAndReadyTestScenario {
    function setUp() public virtual override {
        srcChain = "avalanche";
        dstChain = "arbitrum";
        super.setUp();
    }
}
