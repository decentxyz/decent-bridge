// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {OpenDcntEth} from "../../test/common/OpenDcntEth.sol";
import {DecentEthRouter} from "../../src/DecentEthRouter.sol";
import {LzChainSetup} from "arshans-forge-toolkit/LzChainSetup.sol";
import {RouterDeploymentSetup} from "../../test/common/RouterDeploymentSetup.sol";

contract LoadDeployedContracts is LzChainSetup, RouterDeploymentSetup {
    function loadForChain(string memory chain) public {
        routerLookup[chain] = DecentEthRouter(
            payable(getDeployment(chain, "router"))
        );

        dcntEthLookup[chain] = OpenDcntEth(getDeployment(chain, "dcntEth"));
    }

    function loadAllAddresses(string[] memory chains) public {
        for (uint i = 0; i < chains.length; i++) {
            string memory chain = chains[i];
            loadForChain(chain);
        }
    }
}
