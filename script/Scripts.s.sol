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
