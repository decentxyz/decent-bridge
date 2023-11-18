// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Endpoint} from "./Endpoint.sol";
import {BaseChainSetup} from "./BaseChainSetup.sol";

contract LzChainSetup is BaseChainSetup {
    mapping(string => Endpoint) lzEndpointLookup;
    mapping(string => uint16) lzIdLookup;

    function configureLzChain(
        string memory chain,
        uint16 lzId,
        address lzEndpoint
    ) internal {
        // from here: https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
        lzEndpointLookup[chain] = Endpoint(lzEndpoint);
        lzIdLookup[chain] = lzId;
    }
}
