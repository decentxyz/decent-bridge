// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {MultichainDeployer} from "./MultichainDeployer.sol";
import {AllChainsInfo} from "./AllChainsInfo.sol";

contract TestMultichainSetup is MultichainDeployer, AllChainsInfo {
    function setUp() public virtual {
        setRuntime(ENV_FORGE_TEST);
        setupChainInfo();
    }
}
