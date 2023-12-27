// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {console2} from "forge-std/console2.sol";
import {LoadDecentBridgeDeployedContracts} from "../../script/util/LoadDecentBridgeDeployedContracts.sol";
import {BalanceAssertions} from "forge-toolkit/BalanceAssertions.sol";
import {AliceAndBobScenario} from "./AliceAndBobScenario.sol";
import {CoolCatScenario} from "./CoolCatScenario.sol";

contract DeployedAndReadyTestScenario is
    CoolCatScenario,
    AliceAndBobScenario,
LoadDecentBridgeDeployedContracts,
    BalanceAssertions
{
    bool load = false;
    uint256 AVAILABLE_LIQUIDITY = 10 ether;

    function addLiquidityMintWethToSelfIfNeeded(
        string memory chain,
        uint amount
    ) public {
        if (!gasEthLookup[chain]) {
            mintWethTo(chain, address(this), amount);
        }
        addLiquidity(chain, amount);
    }

    function setUp() public virtual {
        setRuntime(ENV_FORGE_TEST);
        if (bytes(srcChain).length == 0) {
            revert("srcChain not set");
        }
        if (bytes(dstChain).length == 0) {
            revert("dstChain not set");
        }
        loadAllChainInfo();
        setupWethHelperInfo();
        if (load) {
            loadDecentBridgeContractsForChain(srcChain);
            loadDecentBridgeContractsForChain(dstChain);
        } else {
            setSkipFile(true);
            deploySrcDst();
        }
        addLiquidityMintWethToSelfIfNeeded(srcChain, AVAILABLE_LIQUIDITY);
        addLiquidityMintWethToSelfIfNeeded(dstChain, AVAILABLE_LIQUIDITY);
    }
}
