// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IWETH} from "./interfaces/IWETH.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {IDecentBridgeExecutor} from "./interfaces/IDecentBridgeExecutor.sol";

contract DecentBridgeExecutor is IDecentBridgeExecutor, Owned {
    IWETH weth;
    bool public gasCurrencyIsEth; // for chains that use ETH as gas currency

    constructor(address _weth, bool gasIsEth) Owned(msg.sender) {
        weth = IWETH(payable(_weth));
        gasCurrencyIsEth = gasIsEth;
    }

    /**
     * @dev helper function for execute
     * @param from caller of the function
     * @param target target contract
     * @param amount amount of the in eth
     * @param callPayload payload for the tx
     */
    function _executeWeth(
        address from,
        address target,
        uint256 amount,
        bytes memory callPayload
    ) private {
        uint256 balanceBefore = weth.balanceOf(address(this));
        weth.approve(target, amount);

        (bool success, ) = target.call(callPayload);

        if (!success) {
            weth.transfer(from, amount);
            return;
        }

        uint256 remainingAfterCall = amount -
            (balanceBefore - weth.balanceOf(address(this)));

        // refund the sender with excess WETH
        weth.transfer(from, remainingAfterCall);
    }

    /**
     * @dev helper function for execute
     * @param from caller of the function
     * @param target target contract
     * @param amount amount of the transaction
     * @param callPayload payload for the tx
     */
    function _executeEth(
        address from,
        address target,
        uint256 amount,
        bytes memory callPayload
    ) private {
        weth.withdraw(amount);
        (bool success, ) = target.call{value: amount}(callPayload);
        if (!success) {
            payable(from).transfer(amount);
        }
    }

    /// @inheritdoc IDecentBridgeExecutor
    function execute(
        address from,
        address target,
        bool deliverEth,
        uint256 amount,
        bytes memory callPayload
    ) public onlyOwner {
        weth.transferFrom(msg.sender, address(this), amount);

        if (!gasCurrencyIsEth || !deliverEth) {
            _executeWeth(from, target, amount, callPayload);
        } else {
            _executeEth(from, target, amount, callPayload);
        }
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
