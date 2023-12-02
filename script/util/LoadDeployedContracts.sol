// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {OpenDcntEth} from "../../test/common/OpenDcntEth.sol";
import {DecentEthRouter} from "../../src/DecentEthRouter.sol";
import {LzChainSetup} from "arshans-forge-toolkit/LzChainSetup.sol";
import {RouterDeploymentSetup} from "../../test/common/RouterDeploymentSetup.sol";

contract LoadDeployedContracts is LzChainSetup, RouterDeploymentSetup {
    string deployFile = "./deployments/deployedAddresses.json";

    function jsonReadAddress(
        string memory filePath,
        string memory keypath
    ) public view returns (address deployment) {
        string memory fileContent = vm.readFile(filePath);
        return vm.parseJsonAddress(fileContent, keypath);
    }

    function getChainDeploymentFile(
        string memory chain
    ) public pure returns (string memory) {
        return string.concat("./deployments/", chain, "Addresses.json");
    }

    function loadForChain(string memory chain) public {
        routerLookup[chain] = DecentEthRouter(
            payable(jsonReadAddress(getChainDeploymentFile(chain), ".router"))
        );

        dcntEthLookup[chain] = OpenDcntEth(
            jsonReadAddress(getChainDeploymentFile(chain), ".decentEth")
        );
    }

    function loadAllAddresses(string[] memory chains) public {
        for (uint i = 0; i < chains.length; i++) {
            string memory chain = chains[i];
            loadForChain(chain);
        }
    }
}
