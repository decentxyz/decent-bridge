// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {CommonBase} from "forge-std/Base.sol";

contract DeploymentRecorder is CommonBase {
    string folderName = "deployments";
    string recorderKey = "addresses";

    function _chainRecordKey(
        string memory chain
    ) private pure returns (string memory) {
        return string.concat(chain, "deployments");
    }

    function startRecording(
        string memory chain
    ) internal pure returns (string memory) {
        return _chainRecordKey(chain);
    }

    function dumpChainDeployments(string memory chain) internal {
        string memory deployedAddresses = vm.serializeBool(
            _chainRecordKey(chain),
            "done",
            true
        );
        vm.writeJson(
            deployedAddresses,
            string.concat(folderName, "/", chain, "Addresses.json")
        );
    }
}