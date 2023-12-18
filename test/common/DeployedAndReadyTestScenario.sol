// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {AliceAndBobScenario} from "./AliceAndBobScenario.sol";
import {console2} from "forge-std/console2.sol";
import {CoolCatScenario} from "./CoolCatScenario.sol";
import {LoadDeployedContracts} from "../../script/util/LoadDeployedContracts.sol";
import {LoadAllChainInfo} from "arshans-forge-toolkit/LoadAllChainInfo.sol";
import {BalanceAssertions} from "arshans-forge-toolkit/BalanceAssertions.sol";
import {WethMintHelper} from "arshans-forge-toolkit/WethMintHelper.sol";

contract DeployedAndReadyTestScenario is
    AliceAndBobScenario,
    BalanceAssertions,
    LoadAllChainInfo,
    WethMintHelper,
    CoolCatScenario,
    LoadDeployedContracts
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
            loadForChain(srcChain);
            loadForChain(dstChain);
        } else {
            setSkipFile(true);
            deploySrcDst();
        }
        addLiquidityMintWethToSelfIfNeeded(srcChain, AVAILABLE_LIQUIDITY);
        addLiquidityMintWethToSelfIfNeeded(dstChain, AVAILABLE_LIQUIDITY);
    }
}
