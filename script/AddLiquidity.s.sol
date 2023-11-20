// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {BroadcastMultichainSetup} from "./util/BroadcastMultichainSetup.sol";
import {ParseChainsFromEnvVars} from "./util/ParseChainsFromEnvVars.sol";
import {RouterActions} from "../test/common/RouterActions.sol";
import {WethMintHelper} from "../test/common/WethMintHelper.sol";
import {LoadDeployedContracts} from "./util/LoadDeployedContracts.sol";

contract AddLiquidity is
    Script,
    BroadcastMultichainSetup,
    ParseChainsFromEnvVars,
    RouterActions,
    WethMintHelper,
    LoadDeployedContracts
{
    function run() public {
        setupWhaleInfo();
        string[] memory chains = getChains();
        loadAllAddresses(chains);
        uint amount = vm.envUint("LIQUIDITY");
        if (isTestnet()) {
            return addLiqFtmSepoloiaTreatFtmAsGasEth(amount);
        }

        for (uint i = 0; i < chains.length; i++) {
            string memory chain = chains[i];
            if (!isMainnet() && !gasEthLookup[chain]) {
                mintWethTo(chain, address(msg.sender), amount);
            }
            addLiquidity(chain, amount);
        }
    }

    function addLiqFtmSepoloiaTreatFtmAsGasEth(uint amount) public {
        // for now treatingt
        gasEthLookup["ftm-testnet"] = true;
        wethLookup["ftm-testnet"] = 0x07B9c47452C41e8E00f98aC4c075F5c443281d2A;
        addLiquidity("sepolia", amount);
        addLiquidity("ftm-testnet", amount);
    }
}
