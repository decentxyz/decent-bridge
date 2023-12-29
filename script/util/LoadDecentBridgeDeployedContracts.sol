// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {DcntEth} from "../../src/DcntEth.sol";
import {DecentEthRouter} from "../../src/DecentEthRouter.sol";
import {DecentBridgeExecutor} from "../../src/DecentBridgeExecutor.sol";
import {LzChainSetup} from "forge-toolkit/LzChainSetup.sol";
import {DecentBridgeDeploymentSetup} from "../../test/common/DecentBridgeDeploymentSetup.sol";

contract LoadDecentBridgeDeployedContracts is
    LzChainSetup,
    DecentBridgeDeploymentSetup
{
    function loadDecentBridgeContractsForChain(string memory chain) public {
        routerLookup[chain] = DecentEthRouter(
            payable(getDeployment(chain, "DecentEthRouter"))
        );
        dcntEthLookup[chain] = DcntEth(getDeployment(chain, "DcntEth"));
        decentBridgeExecutorLookup[chain] = DecentBridgeExecutor(
            payable(getDeployment(chain, "DecentBridgeExecutor"))
        );
    }

    function loadAllDecentBridgeAddresses(string[] memory chains) public {
        for (uint i = 0; i < chains.length; i++) {
            string memory chain = chains[i];
            loadDecentBridgeContractsForChain(chain);
        }
    }
}
