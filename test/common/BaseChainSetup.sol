// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {console2} from "forge-std/console2.sol";
import {CommonBase} from "forge-std/Base.sol";

contract BaseChainSetup is CommonBase {
    bool internal isTestRuntime = true;
    bool broadcasting = false;

    mapping(string => uint256) forkLookup;
    mapping(string => bool) gasEthLookup;
    mapping(string => address) wethLookup;
    mapping(string => uint256) chainIdLookup;

    function setRuntime(bool _isTestRuntime) internal {
        isTestRuntime = _isTestRuntime;
    }

    function _forkAlias(
        string memory _chain
    ) internal view returns (string memory) {
        return isTestRuntime ? _chain : string.concat("fork_", _chain);
    }

    function startImpersonating(address _as) internal {
        console2.log("impersonating as", _as);
        if (isTestRuntime) {
            vm.startPrank(_as);
        } else {
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
        forkLookup[chain] = vm.createFork(_forkAlias(chain));
        gasEthLookup[chain] = isGasEth;
        wethLookup[chain] = weth;
        chainIdLookup[chain] = chainId;
    }

    function stopImpersonating() internal {
        if (isTestRuntime) {
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

        if (!isTestRuntime && broadcasting) {
            vm.stopBroadcast();
            broadcasting = false;
        }

        vm.selectFork(forkLookup[chain]);

        if (!isTestRuntime) {
            vm.startBroadcast();
            broadcasting = true;
        }
    }

    function dealTo(
        string memory chain,
        address user,
        uint256 amount
    ) internal {
        switchTo(chain);
        if (isTestRuntime) {
            vm.deal(user, amount);
        } else {
            user.call{value: amount}("");
        }
    }
}
