// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {CommonBase} from "forge-std/Base.sol";
import {DecentEthRouter} from "src/DecentEthRouter.sol";
import {DcntEth} from "src/DcntEth.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract BridgedWeth is ERC20("Wrapped Ether", "WETH", 18) {
    function mint(address to, uint amount) external {
        _mint(to, amount);
    }
}

contract DeployRouter is Script {
    string chainAlias;
    WETH weth;
    address lzEndpoint;
    bool isGasEth;
    bool isMainnet;

    function setupWeth() public virtual {}

    function run() public {
        vm.createSelectFork(chainAlias);
        vm.startBroadcast();
        setupWeth();
        DecentEthRouter router = new DecentEthRouter(
            payable(address(weth)),
            isGasEth
        );
        DcntEth dcntEth = new DcntEth(lzEndpoint);
        dcntEth.transferOwnership(address(router));
        router.registerDcntEth(address(dcntEth));
        vm.stopBroadcast();
    }
}

contract EnvironmentVarTest is Script {
    function run() public view {
        string memory chainAlias = vm.envString("CHAIN");
        address lzEndpoint = vm.envAddress("LZ_ENDPOINT");
        bool isGasEth = vm.envBool("GAS_ETH");
        console2.log("chain Alias", chainAlias);
        console2.log("lz endpoint", lzEndpoint);
        console2.log("is gas eth", isGasEth);
    }
}

contract DeployToChain is DeployRouter {
    function setupWeth() public override {
        if (!isMainnet && !isGasEth) {
            BridgedWeth custom_weth = new BridgedWeth();
            weth = WETH(payable(address(custom_weth)));
        } else {
            weth = WETH(payable(vm.envAddress("WETH")));
        }
        console2.log("weth", address(weth));
    }

    constructor() {
        lzEndpoint = vm.envAddress("LZ_ENDPOINT");
        chainAlias = vm.envString("CHAIN");
        isMainnet = vm.envBool("MAINNET");
        isGasEth = vm.envBool("GAS_ETH");
        console2.log("lz endpoint", lzEndpoint);
        console2.log("chain Alias", chainAlias);
        console2.log("running in mainnet", isMainnet);
        console2.log("is gas eth", isGasEth);
    }
}
