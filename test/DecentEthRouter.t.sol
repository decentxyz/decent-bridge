// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console, console2} from "forge-std/Test.sol";
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {OFTV2} from "solidity-examples/token/oft/v2/OFTV2.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {DecentEthRouter} from "src/DecentEthRouter.sol";
import {DcntEth} from "src/DcntEth.sol";
import {CommonRouterSetup} from "test/util/CommonRouterSetup.sol";

contract DecentEthRouterEthChainTest is CommonRouterSetup {
    WETH weth;
    // arbitrum mainnet
    address lzEndpointArbitrum = 0x3c2269811836af69497E5F486A85D7316753cf62;
    bool isGasEth = true;

    function setUp() public {
        uint arbiFork = vm.createSelectFork("arbitrum");
        assertEq(vm.activeFork(), arbiFork);
        weth = new WETH();
        router = new DecentEthRouter(payable(address(weth)), isGasEth);
        router.deployDcntEth(lzEndpointArbitrum);
        dcntEth = router.dcntEth();
    }

    function addLiquidity(uint amount) internal {
        router.addLiquidityEth{value: amount}();
    }

    function testShouldBeAbletoDepositAndWithdrawEth() public {
        addLiquidity(10);
        assertEq(weth.balanceOf(address(router)), 10);
        assertEq(dcntEth.balanceOf(address(router)), 10);

        router.removeLiquidityEth(5);
        assertEq(weth.balanceOf(address(router)), 5);
        assertEq(dcntEth.balanceOf(address(router)), 5);
    }

    function testShouldBeAbletoDepositAndWithdrawWeth() public {
        uint amount = 10;
        weth.deposit{value: amount}();
        weth.approve(address(router), amount);
        router.addLiquidityWeth(amount);
        assertEq(weth.balanceOf(address(router)), amount);
        assertEq(dcntEth.balanceOf(address(router)), amount);

        uint withdrawAmt = 5;
        router.removeLiquidityWeth(withdrawAmt);
        assertEq(weth.balanceOf(address(router)), amount - withdrawAmt);
        assertEq(dcntEth.balanceOf(address(router)), amount - withdrawAmt);
    }

    function testShouldNotBeAbleToWithdrawMoreThanDeposited() public {
        uint amount = 10;
        weth.deposit{value: amount}();
        weth.approve(address(router), amount);
        router.addLiquidityWeth(amount);

        vm.expectRevert();
        router.removeLiquidityWeth(amount + 10);
    }

    function testAddDestinationChain() public {
        setUpDstRouter();
    }

    function testBridgeEthShouldAttemptToBridge() public {
        addLiquidity(20);
        setupAndBridge(10);
        assertEq(weth.balanceOf(address(router)), 30); // 20 + 10 bridged
        assertEq(dcntEth.balanceOf(address(router)), 10); // 20 - 10 bridged
        assertEq(address(router).balance, 0);
    }

    function testBridgeEthShouldFailIfTheresNotEnoughLiquidity() public {
        addLiquidity(10);
        (
            uint16 dstLzOpId,
            DecentEthRouter dstRouter,
            DcntEth dstDcntEth
        ) = setUpDstRouter();

        uint amount = 20;
        address toAddress = msg.sender;

        (uint nativeFee, uint zroFee) = router.estimateSendAndCallFee(
            dstLzOpId,
            toAddress,
            amount,
            DST_GAS_FOR_CALL
        );
        vm.expectRevert("ERC20: burn amount exceeds balance");
        router.bridgeEth{value: amount + nativeFee + zroFee}(
            dstLzOpId,
            toAddress,
            amount,
            DST_GAS_FOR_CALL
        );
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
