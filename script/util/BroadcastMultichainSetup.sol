// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {MultichainDeployer} from "../../test/common/MultichainDeployer.sol";
import {LoadAllChainInfo} from "arshans-forge-toolkit/LoadAllChainInfo.sol";

contract BroadcastMultichainSetup is MultichainDeployer, LoadAllChainInfo {
    function setUp() public virtual {
        setRuntime(ENV_FORK);
        loadAllChainInfo();
    }
}
