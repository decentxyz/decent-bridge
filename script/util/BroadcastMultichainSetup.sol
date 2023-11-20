// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {MultichainDeployer} from "../../test/common/MultichainDeployer.sol";
import {AllChainsInfo} from "../../test/common/AllChainsInfo.sol";

contract BroadcastMultichainSetup is MultichainDeployer, AllChainsInfo {
    function setUp() public virtual {
        setRuntime(ENV_FORK);
        setupChainInfo();
    }
}
