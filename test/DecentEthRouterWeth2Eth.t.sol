// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {AliceAndBobScenario} from "./common/AliceAndBobScenario.sol";
import {WethMintHelper} from "./common/WethMintHelper.sol";
import {CoolCat} from "./common/CoolCat.sol";
import {WethChain2EthChainScenario} from "./common/WethChain2EthChainScenario.sol";
import {AssertionHelpers} from "./common/AssertionHelpers.sol";

contract SourceChainWethCommonHelpers is
    AliceAndBobScenario,
    AssertionHelpers,
    WethMintHelper
{
    uint aliceNonEthBalance = 1 ether; //
    uint aliceInitialWethBalance = 10 ether;
    uint bridgeAmount = 6.9 ether;

    function _aliceGaveHerMoneyOnSrcChain(uint fees) internal {
        switchTo(srcChain);
        assertWethBalanceEq(
            srcChain,
            alice,
            aliceInitialWethBalance - bridgeAmount
        );
        assertApproxEqRel(
            alice.balance,
            aliceNonEthBalance - fees,
            0.001 ether
        );
    }

    function setupAlice() internal {
        dealTo(srcChain, alice, aliceNonEthBalance);
        mintWethTo(srcChain, alice, aliceInitialWethBalance);
    }
}

contract DecentEthRouterWeth2EthTest is
    WethChain2EthChainScenario,
    SourceChainWethCommonHelpers
{
    function testBridgeEthFromWethChainShouldDeliverEthToEthChain() public {
        setupAlice();
        uint fees = sendAliceToBobAndReceiveDeliverEth(bridgeAmount);
        assertEthBalanceEq(dstChain, bob, bridgeAmount);
        _aliceGaveHerMoneyOnSrcChain(fees);
    }

    function testBridgeEthWithWethDeliveryShouldDeliverWeth() public {
        setupAlice();
        uint fees = sendAliceToBobAndReceiveDeliverWeth(bridgeAmount);
        assertWethBalanceEq(dstChain, bob, bridgeAmount);
        _aliceGaveHerMoneyOnSrcChain(fees);
    }

    function testFailBridgeEthShouldFailIfTheresNotEnoughLiquidity() public {
        setupAlice();
        mintWethTo(srcChain, alice, AVAILABLE_LIQUIDITY + 10 ether);
        sendAliceToBobAndReceiveDeliverEth(AVAILABLE_LIQUIDITY + 1 ether);
    }

    function testWeth2EthCallTargetShouldRefundTheSenderWithAnyExcessWeth()
        public
    {
        setupAlice();
        CoolCat coolCat = birthCoolCat();

        uint fees = sendAliceToTargetAndReceive(
            bridgeAmount,
            false,
            address(coolCat),
            GAS_FOR_MEOW_MEOW,
            abi.encodeCall(coolCat.meowReceiveWeth, (1 ether))
        );

        assertEthBalanceEq(dstChain, address(coolCat), 0);
        assertWethBalanceEq(dstChain, address(coolCat), 1 ether);
        assertWethBalanceEq(dstChain, alice, bridgeAmount - 1 ether);
        _aliceGaveHerMoneyOnSrcChain(fees);
    }

    function testFromWethChainShouldMakeACatOnEthChainGoMeowWithWeth() public {
        setupAlice();
        CoolCat coolCat = birthCoolCat();
        uint amount = bridgeAmount;

        uint fees = sendAliceToTargetAndReceive(
            amount,
            false,
            address(coolCat),
            GAS_FOR_MEOW_MEOW,
            abi.encodeCall(coolCat.meowWethThenUnwrap, (bridgeAmount))
        );

        assertEthBalanceEq(dstChain, address(coolCat), bridgeAmount);
        _aliceGaveHerMoneyOnSrcChain(fees);
    }

    function testIfDestinationEthDeliveryCallAtEthChainFailsAliceShouldGetHerBridgedMoneyBackInEth()
        public
    {
        setupAlice();
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

        _aliceGaveHerMoneyOnSrcChain(fees);
    }

    function testIfDestinationWethDeliveryCallFailsAliceShouldGetHerBridgedWethMoneyBack()
        public
    {
        setupAlice();
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

        _aliceGaveHerMoneyOnSrcChain(fees);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
