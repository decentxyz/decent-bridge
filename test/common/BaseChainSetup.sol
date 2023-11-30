// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {console2} from "forge-std/console2.sol";
import {CommonBase} from "forge-std/Base.sol";

contract BaseChainSetup is CommonBase {
    string private runtime;

    string constant ENV_FORGE_TEST = "forge-test";
    string constant ENV_FORK = "fork";
    string constant ENV_TESTNET = "testnet";
    string constant ENV_MAINNET = "mainnet";

    bool broadcasting = false;

    mapping(string => uint256) forkLookup;
    mapping(string => bool) gasEthLookup;
    mapping(string => address) wethLookup;
    mapping(string => uint256) chainIdLookup;
    mapping(string => bool) chainIsSet;

    function isMainnet() public returns (bool) {
        return vm.envOr("MAINNET", false) && strCompare(runtime, ENV_MAINNET);
    }

    function isTestnet() public returns (bool) {
        return vm.envOr("TESTNET", false) && strCompare(runtime, ENV_TESTNET);
    }

    function strCompare(
        string memory s1,
        string memory s2
    ) public pure returns (bool) {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function isForgeTest() public view returns (bool) {
        return strCompare(runtime, ENV_FORGE_TEST);
    }

    function isForkRuntime() public view returns (bool) {
        return strCompare(runtime, ENV_FORK);
    }

    function setRuntime(string memory _runtime) internal {
        runtime = _runtime;
    }

    function _forkAlias(
        string memory _chain
    ) internal view returns (string memory) {
        return isForkRuntime() ? string.concat("fork_", _chain) : _chain;
    }

    function startImpersonating(address _as) internal {
        console2.log("impersonating as", _as);
        if (isForgeTest()) {
            vm.startPrank(_as);
        } else if (isForkRuntime()) {
            vm.stopBroadcast();
            vm.startBroadcast(_as);
        }
    }

    function configureChain(
        string memory chain,
        bool isGasEth,
        uint256 chainId,
        address weth
    ) public {
        try vm.createFork(_forkAlias(chain)) returns (uint256 forkId) {
            forkLookup[chain] = forkId;
        } catch {}
        gasEthLookup[chain] = isGasEth;
        wethLookup[chain] = weth;
        chainIdLookup[chain] = chainId;
    }

    function stopImpersonating() internal {
        if (isForgeTest()) {
            vm.stopPrank();
        } else {
            vm.stopBroadcast();
            vm.startBroadcast();
        }
    }

    function switchTo(string memory chain) internal {
        if (bytes(chain).length == 0) {
            revert("no chain specified");
        }

        if (!chainIsSet[chain]) {
            revert(string.concat("no info found for chain: ", chain));
        }

        if (!isForgeTest() && broadcasting) {
            vm.stopBroadcast();
            broadcasting = false;
        }
        uint forkId = forkLookup[chain];

        vm.selectFork(forkId);

        if (!isForgeTest()) {
            vm.startBroadcast();
            broadcasting = true;
        }
    }

    function dealTo(
        string memory chain,
        address user,
        uint256 amount
    ) internal returns (bool success) {
        success = true;
        switchTo(chain);
        if (isForgeTest()) {
            vm.deal(user, amount);
        } else {
            (success, ) = user.call{value: amount}("");
        }
    }
}
