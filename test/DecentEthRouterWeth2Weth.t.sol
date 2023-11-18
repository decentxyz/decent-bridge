// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {SourceChainWethCommonHelpers} from "./DecentEthRouterWeth2Eth.t.sol";
import {Test, console2} from "forge-std/Test.sol";
import {CoolCat} from "./common/CoolCat.sol";
import {WethChain2WethChainScenario} from "./common/WethChain2WethChainScenario.sol";

contract DecentEthRouterWeth2WethTest is
    WethChain2WethChainScenario,
    SourceChainWethCommonHelpers
{
    function testWeth2WethBridgeEthDeliveryShouldStillDeliverWeth() public {
        setupAlice();
        uint fees = sendAliceToBobAndReceiveDeliverEth(bridgeAmount);
        assertWethBalanceEq(dstChain, bob, bridgeAmount);
        _aliceGaveHerMoneyOnSrcChain(fees);
    }

    function testWeth2WethBridgeWethShouldDeliverWeth() public {
        setupAlice();
        uint fees = sendAliceToBobAndReceiveDeliverWeth(bridgeAmount);
        assertWethBalanceEq(dstChain, bob, bridgeAmount);
        _aliceGaveHerMoneyOnSrcChain(fees);
    }

    function testFailIfBridgingMoreThanAvailLiquidity() public {
        setupAlice();
        mintWethTo(srcChain, alice, AVAILABLE_LIQUIDITY + 10 ether);
        sendAliceToBobAndReceiveDeliverEth(AVAILABLE_LIQUIDITY + 1 ether);
    }

    function testWeth2WethCallTargetShouldRefundTheSenderWithAnyExcessWeth()
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

    function testFromWethShouldMakeCatGoMeowWithWeth() public {
        setupAlice();
        CoolCat coolCat = birthCoolCat();
        uint amount = bridgeAmount;

        uint fees = sendAliceToTargetAndReceive(
            amount,
            false,
            address(coolCat),
            GAS_FOR_MEOW_MEOW,
            abi.encodeCall(coolCat.meowReceiveWeth, (bridgeAmount))
        );

        assertWethBalanceEq(dstChain, address(coolCat), bridgeAmount);
        _aliceGaveHerMoneyOnSrcChain(fees);
    }

    function testIfDestinationEthDeliveryCallAtEthChainFailsAliceShouldGetHerBridgedMoneyBackInWeth()
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
