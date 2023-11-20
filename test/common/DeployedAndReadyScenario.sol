// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {AliceAndBobScenario} from "./AliceAndBobScenario.sol";
import {AssertionHelpers} from "./AssertionHelpers.sol";
import {AllChainsInfo} from "./AllChainsInfo.sol";
import {console2} from "forge-std/console2.sol";
import {WethMintHelper} from "./WethMintHelper.sol";
import {CoolCatScenario} from "./CoolCatScenario.sol";

contract DeployedAndReadyTestScenario is
    AliceAndBobScenario,
    AssertionHelpers,
    AllChainsInfo,
    WethMintHelper,
    CoolCatScenario
{
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
        setupChainInfo();
        setupWhaleInfo();
        deploySrcDst();
        addLiquidityMintWethToSelfIfNeeded(srcChain, AVAILABLE_LIQUIDITY);
        addLiquidityMintWethToSelfIfNeeded(dstChain, AVAILABLE_LIQUIDITY);
    }
}
