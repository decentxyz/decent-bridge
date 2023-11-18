// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {BaseChainSetup} from "./BaseChainSetup.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Test} from "forge-std/Test.sol";

contract AssertionHelpers is BaseChainSetup, Test {
    function assertTokenBalanceEq(
        string memory chain,
        address user,
        address token,
        uint256 amount
    ) internal {
        switchTo(chain);
        assertEq(ERC20(token).balanceOf(user), amount);
    }

    function assertWethBalanceEq(
        string memory chain,
        address user,
        uint256 amount
    ) internal {
        assertTokenBalanceEq(chain, user, wethLookup[chain], amount);
    }

    function assertEthBalanceEq(
        string memory chain,
        address user,
        uint256 amount
    ) internal {
        assertEq(ethBalance(chain, user), amount);
    }

    function ethBalance(
        string memory chain,
        address user
    ) internal returns (uint256) {
        switchTo(chain);
        return user.balance;
    }

    function wethBalance(
        string memory chain,
        address user
    ) internal returns (uint256) {
        switchTo(chain);
        return ERC20(wethLookup[chain]).balanceOf(user);
    }
}
