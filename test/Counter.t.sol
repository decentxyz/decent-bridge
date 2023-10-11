// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Counter.sol";
import "forge-std/console2.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new  Counter();
        counter.setNumber(0);
    }

    function testIncrement() public {
        console.log("henlo");
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testSetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}
