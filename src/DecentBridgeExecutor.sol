// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IWETH} from "./interfaces/IWETH.sol";
import {IDecentBridgeExecutor} from "./interfaces/IDecentBridgeExecutor.sol";
import {Operable} from "./utils/Operable.sol";

contract DecentBridgeExecutor is IDecentBridgeExecutor, Operable {
    IWETH public weth;
    bool public gasCurrencyIsEth; // for chains that use ETH as gas currency

    constructor(address _weth, bool gasIsEth) {
        weth = IWETH(payable(_weth));
        gasCurrencyIsEth = gasIsEth;
    }

    /**
     * @dev helper function for execute
     * @param refundAddress the refund address
     * @param target target contract
     * @param amount amount of the in eth
     * @param callPayload payload for the tx
     */
    function _executeWeth(
        address refundAddress,
        address target,
        uint256 amount,
        bytes memory callPayload
    ) private {
        uint256 balanceBefore = weth.balanceOf(address(this));
        weth.approve(target, amount);

        (bool success, ) = target.call(callPayload);

        if (!success) {
            weth.transfer(refundAddress, amount);
            return;
        }

        uint256 remainingAfterCall = amount -
            (balanceBefore - weth.balanceOf(address(this)));

        // refund the sender with excess WETH
        weth.transfer(refundAddress, remainingAfterCall);
    }

    /**
     * @dev helper function for execute
     * @param refundAddress the address to be refunded
     * @param target target contract
     * @param amount amount of the transaction
     * @param callPayload payload for the tx
     */
    function _executeEth(
        address refundAddress,
        address target,
        uint256 amount,
        bytes memory callPayload
    ) private {
        weth.withdraw(amount);
        (bool success, ) = target.call{value: amount}(callPayload);
        if (!success) {
            (payable(refundAddress).call{value: amount}(""));
        }
    }

    /// @inheritdoc IDecentBridgeExecutor
    function execute(
        address refundAddress,
        address target,
        bool deliverEth,
        uint256 amount,
        bytes memory callPayload
    ) public onlyOperator {
        weth.transferFrom(msg.sender, address(this), amount);

        if (!gasCurrencyIsEth || !deliverEth) {
            _executeWeth(refundAddress, target, amount, callPayload);
        } else {
            _executeEth(refundAddress, target, amount, callPayload);
        }
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
