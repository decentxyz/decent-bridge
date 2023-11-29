// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {MockEndpoint} from "./common/Endpoint.sol";
import {Test} from "forge-std/Test.sol";
import {TestMultichainSetup} from "./common/TestMultichainSetup.sol";
import {LoadDeployedContracts} from "../script/util/LoadDeployedContracts.sol";

contract GasReport is Test, TestMultichainSetup, LoadDeployedContracts {
    function skipTestCallRetryPayload() public {
        string memory src = "sepolia";
        string memory dst = "zora-goerli";
        loadForChain(src);
        loadForChain(dst);
        address srcUa = address(dcntEthLookup[src]);
        address dstUa = address(dcntEthLookup[dst]);
        bytes memory srcPath = abi.encodePacked(srcUa, dstUa);
        MockEndpoint dstEndpoint = lzEndpointLookup[dst];
        switchTo(dst);
        bytes
            memory payload = hex"01000000000000000000000000c6e0926eaef49268eda6be3259e0a56f66cfec9c000009184e72a0000000000000000000000000005872eace9484d15fbc2ef6de6efd8613c5bf22b90000000000030d4000000000000000000000000000000000000000000000000000000000000000010000000000000000000000005d7370fcd6e446bbc14a64c1effe5fbb1c893232000000000000000000000000d643567b131777cd52841ca1ff7663ba890a0092000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000002440d097c30000000000000000000000005d7370fcd6e446bbc14a64c1effe5fbb1c89323200000000000000000000000000000000000000000000000000000000";
        dstEndpoint.retryPayload(lzIdLookup[src], srcPath, payload);
    }
}
