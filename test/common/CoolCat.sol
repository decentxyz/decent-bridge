// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {console2} from "forge-std/console2.sol";
import {WETH} from "solmate/tokens/WETH.sol";

contract CoolCat {
    WETH public weth;

    constructor(address payable _weth) {
        weth = WETH(_weth);
    }

    function meowReceiveWeth(uint256 amount) public {
        weth.transferFrom(msg.sender, address(this), amount);
        console2.log(
            "meow! I've received this much WETH not unwrapping it",
            amount
        );
    }

    function meowWethThenUnwrap(uint256 amount) public {
        weth.transferFrom(msg.sender, address(this), amount);
        console2.log("meow! I've received this much WETH", amount);
        weth.withdraw(amount);
    }

    function meowEth() public payable {
        console2.log("meow! I've received this much ETH", msg.value);
    }

    function badMeowMeow() public pure {
        revert("NO MEOW MEOW");
    }

    receive() external payable {}

    fallback() external payable {}
}
