// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {OpenDcntEth} from "../../test/common/OpenDcntEth.sol";
import {DecentEthRouter} from "../../src/DecentEthRouter.sol";
import {LzChainSetup} from "arshans-forge-toolkit/LzChainSetup.sol";
import {DecentBridgeDeploymentSetup} from "../../test/common/DecentBridgeDeploymentSetup.sol";

contract LoadDecentBridgeDeployedContracts is LzChainSetup, DecentBridgeDeploymentSetup {
    function loadDecentBridgeContractsForChain(string memory chain) public {
        routerLookup[chain] = DecentEthRouter(
            payable(getDeployment(chain, "DecentEthRouter"))
        );

        dcntEthLookup[chain] = OpenDcntEth(getDeployment(chain, "DcntEth"));
    }

    function loadAllDecentBridgeAddresses(string[] memory chains) public {
        for (uint i = 0; i < chains.length; i++) {
            string memory chain = chains[i];
            loadDecentBridgeContractsForChain(chain);
        }
    }
}
