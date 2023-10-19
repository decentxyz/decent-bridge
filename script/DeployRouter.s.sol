// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {CommonBase} from "forge-std/Base.sol";
import {DecentEthRouter} from "src/DecentEthRouter.sol";
import {DcntEth} from "src/DcntEth.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

//https://layerzero.gitbook.io/docs/technical-reference/testnet/testnet-addresses
contract BaseScript is Script {
    uint16 FTM_LZ_ID = 10112;
    uint16 FUJI_LZ_ID = 10106;
    uint16 SEPOLIA_LZ_ID = 10161;
    uint MIN_DST_GAS = 100000;
    uint64 DST_GAS_FOR_CALL = 120000;
}

contract BridgedWeth is ERC20("Wrapped Ether", "WETH", 18) {
    function mint(address to, uint amount) external {
        _mint(to, amount);
    }
}

contract DeployRouter is Script {
    string chainAlias;
    BridgedWeth bridgedWeth;
    WETH weth;
    address lzEndpoint;
    bool isGasEth;

    function setupWeth() internal virtual {}

    function run() public {
        uint chainFork = vm.createSelectFork(chainAlias);
        vm.startBroadcast();
        setupWeth();

        DecentEthRouter router;
        if (isGasEth) {
            router = new DecentEthRouter(payable(address(weth)), isGasEth);
        } else {
            router = new DecentEthRouter(
                payable(address(bridgedWeth)),
                isGasEth
            );
        }
        router.deployDcntEth(lzEndpoint);
        uint liquidity = 20;
        if (isGasEth) {
            router.addLiquidityEth{value: liquidity}();
        } else {
            bridgedWeth.mint(address(msg.sender), liquidity);
            bridgedWeth.approve(address(router), liquidity);
            router.addLiquidityWeth(liquidity);
        }

        vm.stopBroadcast();
    }
}

contract DeployFtm is DeployRouter {
    function setupWeth() internal override {
        bridgedWeth = new BridgedWeth();
    }

    constructor() {
        chainAlias = "ftm-testnet";
        lzEndpoint = 0x7dcAD72640F835B0FA36EFD3D6d3ec902C7E5acf;
        isGasEth = false;
    }
}

contract DeploySepolia is DeployRouter {
    constructor() {
        chainAlias = "sepolia";
        weth = WETH(payable(0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9));
        lzEndpoint = 0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1;
        isGasEth = true;
    }
}
