// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console, console2} from "forge-std/Test.sol";
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {OFTV2} from "solidity-examples/token/oft/v2/OFTV2.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {EthChain2EthChainScenario} from "./common/EthChain2EthChainScenario.sol";
import {CoolCat} from "./common/CoolCat.sol";

contract DecentEthRouterEthChainTest is EthChain2EthChainScenario {
    uint alicesBalance = 10 ether;
    uint bridgeAmount = 6.9 ether;

    function _aliceGaveHerMoney(uint fees) private {
        switchTo(srcChain);
        assertApproxEqRel(
            alice.balance,
            alicesBalance - bridgeAmount - fees,
            0.001 ether
        );
    }

    function testBridgeEthShouldDeliverEth() public {
        dealTo(srcChain, alice, 10 ether);
        uint fees = sendAliceToBobAndReceiveDeliverEth(bridgeAmount);
        assertEthBalanceEq(dstChain, bob, bridgeAmount);
        switchTo(srcChain);
        _aliceGaveHerMoney(fees);
    }

    function testBridgeEthWithWethDeliveryShouldDeliverWeth() public {
        dealTo(srcChain, alice, alicesBalance);
        uint fees = sendAliceToBobAndReceiveDeliverWeth(bridgeAmount);
        assertWethBalanceEq(dstChain, bob, bridgeAmount);
        _aliceGaveHerMoney(fees);
    }

    function testFailBridgeEthShouldFailIfTheresNotEnoughLiquidity() public {
        dealTo(srcChain, alice, AVAILABLE_LIQUIDITY + 10 ether);
        sendAliceToBobAndReceiveDeliverEth(AVAILABLE_LIQUIDITY + 1 ether);
    }

    function testShouldMakeACatOnAnotherChainGoMeowWithEth() public {
        dealTo(srcChain, alice, alicesBalance);
        CoolCat coolCat = birthCoolCat();

        uint fees = sendAliceToTargetAndReceive(
            bridgeAmount,
            true,
            address(coolCat),
            GAS_FOR_MEOW_MEOW,
            abi.encodeCall(coolCat.meowEth, ())
        );

        assertEthBalanceEq(dstChain, address(coolCat), bridgeAmount);
        _aliceGaveHerMoney(fees);
    }

    function testShouldMakeACatOnAnotherChainGoMeowWithWeth() public {
        dealTo(srcChain, alice, alicesBalance);
        CoolCat coolCat = birthCoolCat();
        uint amount = bridgeAmount;

        uint fees = sendAliceToTargetAndReceive(
            amount,
            false,
            address(coolCat),
            GAS_FOR_MEOW_MEOW,
            abi.encodeCall(coolCat.meowWethThenUnwrap, (amount))
        );

        assertEthBalanceEq(dstChain, address(coolCat), bridgeAmount);

        _aliceGaveHerMoney(fees);
    }

    function testIfDestinationCallFailsAliceShouldGetHerBridgedMoneyBack()
        public
    {
        dealTo(srcChain, alice, alicesBalance);
        CoolCat coolCat = birthCoolCat();

        uint fees = sendAliceToTargetAndReceive(
            bridgeAmount,
            true,
            address(coolCat),
            GAS_FOR_MEOW_MEOW,
            abi.encodeCall(coolCat.badMeowMeow, ())
        );

        assertEthBalanceEq(dstChain, address(coolCat), 0);
        assertEthBalanceEq(dstChain, alice, bridgeAmount);

        _aliceGaveHerMoney(fees);
    }

    function testIfDestinationCallFailsAliceShouldGetHerBridgedWethMoneyBack()
        public
    {
        dealTo(srcChain, alice, 10 ether);
        CoolCat coolCat = birthCoolCat();

        uint fees = sendAliceToTargetAndReceive(
            bridgeAmount,
            false,
            address(coolCat),
            GAS_FOR_MEOW_MEOW,
            abi.encodeCall(coolCat.badMeowMeow, ())
        );

        assertEthBalanceEq(dstChain, address(coolCat), 0);
        assertWethBalanceEq(dstChain, alice, bridgeAmount);

        _aliceGaveHerMoney(fees);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
