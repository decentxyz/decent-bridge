// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DecentEthRouter} from "../src/DecentEthRouter.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";
import {BroadcastMultichainSetup} from "./util/BroadcastMultichainSetup.sol";
import {ParseChainsFromEnvVars} from "./util/ParseChainsFromEnvVars.sol";
import {LoadDeployedContracts} from "./util/LoadDeployedContracts.sol";
import {MultichainDeployer} from "../test/common/MultichainDeployer.sol";
import {AllChainsInfo} from "../test/common/AllChainsInfo.sol";
import {RouterActions} from "../test/common/RouterActions.sol";
import {MockEndpoint} from "../test/common/Endpoint.sol";

contract FakeWeth is ERC20, Owned {
    constructor() ERC20("Wrapped ETH", "WETH", 18) Owned(msg.sender) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

contract Common is
    Script,
    MultichainDeployer,
    AllChainsInfo,
    ParseChainsFromEnvVars,
    LoadDeployedContracts,
    RouterActions
{
    function overrideFtmTestnet() private {
        gasEthLookup["ftm-testnet"] = true;
        wethLookup["ftm-testnet"] = 0x07B9c47452C41e8E00f98aC4c075F5c443281d2A;
    }

    function setUp() public virtual override {
        if (vm.envOr("TESTNET", false)) {
            setRuntime(ENV_TESTNET);
        } else if (vm.envOr("MAINNET", false)) {
            setRuntime(ENV_MAINNET);
        } else {
            setRuntime(ENV_FORK);
        }
        setupChainInfo();
        overrideFtmTestnet();
    }
}

contract ClearLz is Common {
    function run() public {
        string memory src = vm.envString("src");
        string memory dst = vm.envString("dst");
        loadForChain(src);
        loadForChain(dst);
        address srcUa = address(dcntEthLookup[src]);
        address dstUa = address(dcntEthLookup[dst]);
        bytes memory srcPath = abi.encodePacked(srcUa, dstUa);

        console2.log("srcUa", srcUa);
        console2.log("dstUa", dstUa);
        MockEndpoint dstEndpoint = lzEndpointLookup[dst];
        switchTo(dst);
        dealTo(dst, dstUa, 1 ether);
        startImpersonating(dstUa);
        dstEndpoint.forceResumeReceive(lzIdLookup[src], srcPath);
        stopImpersonating();
    }
}

contract RetryLz is Common {
    function run() public {
        string memory src = vm.envString("src");
        string memory dst = vm.envString("dst");
        loadForChain(src);
        loadForChain(dst);
        address srcUa = address(dcntEthLookup[src]);
        address dstUa = address(dcntEthLookup[dst]);
        bytes memory srcPath = abi.encodePacked(srcUa, dstUa);

        MockEndpoint dstEndpoint = lzEndpointLookup[dst];
        switchTo(dst);
        bytes memory payload = hex"01000000000000000000000000c6e0926eaef49268eda6be3259e0a56f66cfec9c00000000000000010000000000000000000000005872eace9484d15fbc2ef6de6efd8613c5bf22b900000000000493e00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000024d644b055ada775bb20a53c5d90a70698dff9900000000000000000000000097885e75ef7ff6553d7337a47fa32581b7f9fe64000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000002644aed0ae80000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000011a000000000000000000000000000000000000000000000000000000000000011b000000000000000000000000000000000000000000000000000000000000011c000000000000000000000000000000000000000000000000000000000000011d000000000000000000000000000000000000000000000000000000000000011e00000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000419486ae50c868c7942f4a6ce0b20efa2469933febff31014ef2ced80b3e88d09e184ca66e11d3179cc8bcb43921f25ef426afd997ed0a73a006dd2420a6bfbf591c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        dstEndpoint.retryPayload(lzIdLookup[src], srcPath, payload);
    }
}

contract Bridge is Common {
    function run() public {
        uint64 gas = 120e3;
        uint amount = vm.envUint("AMOUNT");
        string memory src = vm.envString("src");
        string memory dst = vm.envString("dst");
        loadForChain(src);
        loadForChain(dst);

        address from = vm.envOr("from", msg.sender);
        address to = vm.envOr("to", msg.sender);

        switchTo(src);
        DecentEthRouter router = routerLookup[src];

        (uint nativeFee, uint zroFee) = router.estimateSendAndCallFee(
            0,
            lzIdLookup[dst],
            to,
            amount,
            gas,
            true,
            ""
        );

        startImpersonating(from);
        router.bridge{value: nativeFee + zroFee + amount}(
            lzIdLookup[dst],
            to,
            amount,
            gas,
            true
        );
        stopImpersonating();
    }
}

contract AddLiquidity is Common {
    function run() public {
        string memory chain = vm.envString("chain");
        uint amount = vm.envUint("LIQUIDITY");
        loadForChain(chain);
        addLiquidity(chain, amount);
    }
}

contract WireUp is Common {
    function run() public {
        string memory src = vm.envString("src");
        string memory dst = vm.envString("dst");
        loadForChain(src);
        loadForChain(dst);
        wireUpSrcToDst(src, dst);
    }
}

contract Deploy is Common {
    function run() public {
        string memory chain = vm.envString("chain");
        console2.log("chain is", chain);
        deployAndRegister(chain);
    }
}
