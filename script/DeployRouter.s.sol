// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {CommonBase} from "forge-std/Base.sol";
import {DecentEthRouter} from "src/DecentEthRouter.sol";
import {DcntEth} from "src/DcntEth.sol";

//https://layerzero.gitbook.io/docs/technical-reference/testnet/testnet-addresses
contract BaseScript is Script {
    uint16 FTM_LZ_ID = 10112;
    uint16 FUJI_LZ_ID = 10106;
    uint16 SEPOLIA_LZ_ID = 10161;
    uint MIN_DST_GAS = 100000;
    uint64 DST_GAS_FOR_CALL = 120000;
}

contract DeployRouter is Script {
    string chainAlias;
    address weth;
    address lzEndpoint;

    function run() public {
        uint chainFork = vm.createSelectFork(chainAlias);
        vm.startBroadcast();
        DecentEthRouter router = new DecentEthRouter(payable(weth));
        router.deployDcntEth(lzEndpoint);
        uint liquidity = 20;
        router.addLiquidityEth{value: liquidity}();
        vm.stopBroadcast();
    }
}

contract DeployFtm is DeployRouter {
    constructor() {
        chainAlias = "ftm-testnet";
        weth = 0x07B9c47452C41e8E00f98aC4c075F5c443281d2A;
        lzEndpoint = 0x7dcAD72640F835B0FA36EFD3D6d3ec902C7E5acf;
    }
}

contract DeploySepolia is DeployRouter {
    constructor() {
        chainAlias = "sepolia";
        weth = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
        lzEndpoint = 0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1;
    }
}
