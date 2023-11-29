// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ILayerZeroEndpoint} from "LayerZero/interfaces/ILayerZeroEndpoint.sol";

abstract contract MockEndpoint is ILayerZeroEndpoint {
    address public defaultReceiveLibraryAddress;
}
