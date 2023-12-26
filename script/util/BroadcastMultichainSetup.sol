// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {MultichainDeployer} from "../../test/common/MultichainDeployer.sol";

contract BroadcastMultichainSetup is MultichainDeployer {
    function setUp() public virtual {
        setRuntime(ENV_FORK);
        loadAllChainInfo();
    }
}
