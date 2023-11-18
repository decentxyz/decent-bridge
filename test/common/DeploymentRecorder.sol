// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {CommonBase} from "forge-std/Base.sol";

contract DeploymentRecorder is CommonBase {
    string recorderKey = "addresses";

    function _chainRecordKey(
        string memory chain
    ) private returns (string memory) {
        return string.concat(chain, "deployments");
    }

    function startRecording(
        string memory chain
    ) internal returns (string memory) {
        return _chainRecordKey(chain);
    }

    function dumpDeployments() internal {
        string memory deployedAddresses = vm.serializeBool(
            recorderKey,
            "done",
            true
        );
        vm.writeJson(deployedAddresses, "broadcast/deployedAddresses.json");
    }

    function stopRecording(string memory chain) internal {
        vm.serializeString(
            recorderKey,
            chain,
            vm.serializeBool(_chainRecordKey(chain), "done", true)
        );
    }
}
