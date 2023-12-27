// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {MultichainDeployer} from "./MultichainDeployer.sol";
import {LoadAllChainInfo} from "forge-toolkit/LoadAllChainInfo.sol";

contract TestMultichainSetup is MultichainDeployer {
    function setUp() public virtual {
        setRuntime(ENV_FORGE_TEST);
        loadAllChainInfo();
    }
}
