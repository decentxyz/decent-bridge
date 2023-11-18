// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ILayerZeroEndpoint} from "solidity-examples/lzApp/interfaces/ILayerZeroEndpoint.sol";

abstract contract Endpoint is ILayerZeroEndpoint {
    address public defaultReceiveLibraryAddress;
}
