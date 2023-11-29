// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {BaseChainSetup} from "./BaseChainSetup.sol";
import {MockEndpoint} from "./Endpoint.sol";

contract LzChainSetup is BaseChainSetup {
    mapping(string => MockEndpoint) lzEndpointLookup;
    mapping(string => uint16) lzIdLookup;

    function configureLzChain(
        string memory chain,
        uint16 lzId,
        address lzEndpoint
    ) internal {
        // from here: https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
        lzEndpointLookup[chain] = MockEndpoint(lzEndpoint);
        lzIdLookup[chain] = lzId;
    }
}
