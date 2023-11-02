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

contract DecentEthRouterNoFork is CommonRouterSetup {
    WETH weth;
    // arbitrum mainnet
    address lzEndpointArbitrum = 0x3c2269811836af69497E5F486A85D7316753cf62;
    bool isGasEth = true;

    function setUp() public {
        weth = new WETH();
        router = new DecentEthRouter(payable(address(weth)), isGasEth);
        router.deployDcntEth(lzEndpointArbitrum);
        dcntEth = router.dcntEth();
    }

    function addLiquidity(uint amount) internal {
        router.addLiquidityEth{value: amount}();
    }

    function testShouldBeAbletoDepositAndWithdrawEth() public {
        uint _depAmt = 10;
        addLiquidity(_depAmt);
        assertEq(weth.balanceOf(address(router)), _depAmt);
        assertEq(dcntEth.balanceOf(address(router)), _depAmt);
        assertEq(router.balanceOf(address(this)), _depAmt);

        uint _withdrawAmt = 5;
        router.removeLiquidityEth(_withdrawAmt);
        assertEq(weth.balanceOf(address(router)), _depAmt - _withdrawAmt);
        assertEq(dcntEth.balanceOf(address(router)), _depAmt - _withdrawAmt);
        assertEq(router.balanceOf(address(this)), _depAmt - _withdrawAmt);
    }

    function testShouldBeAbletoDepositAndWithdrawWeth() public {
        uint amount = 10;
        weth.deposit{value: amount}();
        weth.approve(address(router), amount);
        router.addLiquidityWeth(amount);
        assertEq(weth.balanceOf(address(router)), amount);
        assertEq(dcntEth.balanceOf(address(router)), amount);
        assertEq(router.balanceOf(address(this)), 10);

        uint withdrawAmt = 5;
        router.removeLiquidityWeth(withdrawAmt);
        assertEq(weth.balanceOf(address(router)), amount - withdrawAmt);
        assertEq(dcntEth.balanceOf(address(router)), amount - withdrawAmt);
        assertEq(router.balanceOf(address(this)), amount - withdrawAmt);
    }

    function testShouldNotBeAbleToWithdrawMoreThanDeposited() public {
        uint amount = 10;
        weth.deposit{value: amount}();
        weth.approve(address(router), amount);
        router.addLiquidityWeth(amount);

        vm.expectRevert();
        router.removeLiquidityWeth(amount + 10);
    }

    //function testUserShouldNotBeAbleToRedeemIfTheyDontHaveDecentEth() public {
    //    router.addLiquidityEth{value: 1 ether}();
    //    vm.deal(alice, 0.1 ether);
    //    vm.prank(alice);
    //    vm.expectRevert();
    //    router.redeemEth(0.01 ether);
    //}

    //function testUserShouldBeAbleToRedeem() public {
    //    router.addLiquidityEth{value: 1 ether}();
    //    vm.prank(address(router));
    //    dcntEth.mint(alice, 0.1 ether);
    //    assertEq(alice.balance, 0);
    //    vm.startPrank(alice);
    //    dcntEth.approve(address(router), 0.1 ether);
    //    router.redeemEth(0.04 ether);
    //    assertEq(alice.balance, 0.04 ether);
    //    assertEq(dcntEth.balanceOf(alice), 0.06 ether);

    //    router.redeemEth(0.06 ether);
    //    assertEq(alice.balance, 0.1 ether);
    //    assertEq(dcntEth.balanceOf(alice), 0.00 ether);
    //    vm.stopPrank();
    //}

    function testUserShouldBeGivenDcntEthIfRouterHasNotEnoughBalance() public {
        router.addLiquidityEth{value: 0.1 ether}();

        receiveSomeEth(
            bob, // from
            alice, // to,
            1 ether // amt received
        );

        assertEq(dcntEth.balanceOf(alice), 1 ether);
        assertEq(dcntEth.balanceOf(address(router)), 0.1 ether);
    }

    function testUserShouldBeGivenEthIfRouterHasBalance() public {
        router.addLiquidityEth{value: 2 ether}();

        receiveSomeEth(
            bob, // from
            alice, // to,
            0.69 ether // amt received
        );

        assertEq(dcntEth.balanceOf(alice), 0);

        assertEq(dcntEth.balanceOf(address(router)), 2.69 ether);

        assertEq(alice.balance, 0.69 ether);
        assertEq(weth.balanceOf(address(router)), 2 ether - 0.69 ether);
    }

    //function testUserShouldNotBeAbleToRedeemIfWeDontHaveEnoughReserves()
    //    public
    //{
    //    router.addLiquidityEth{value: 1 ether}();
    //    vm.prank(address(router));
    //    dcntEth.mint(alice, 2 ether);
    //    assertEq(alice.balance, 0);
    //    vm.startPrank(alice);
    //    dcntEth.approve(address(router), 2 ether);
    //    vm.expectRevert("not enough reserves");
    //    router.redeemEth(2 ether);
    //    vm.stopPrank();
    //}

    function testShouldHandlePermissionedWithdrawals() public {
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);

        vm.prank(alice);
        router.addLiquidityEth{value: 0.1 ether}();
        vm.prank(bob);
        router.addLiquidityEth{value: 0.05 ether}();

        assertEq(router.balanceOf(alice), 0.1 ether);
        assertEq(router.balanceOf(bob), 0.05 ether);

        vm.prank(alice);
        router.removeLiquidityEth(0.01 ether);
        assertEq(router.balanceOf(alice), 0.09 ether);

        vm.prank(bob);
        vm.expectRevert("not enough balance");
        router.removeLiquidityEth(0.050001 ether);

        vm.prank(bob);
        router.removeLiquidityEth(0.05 ether);
        assertEq(router.balanceOf(bob), 0);
        assertEq(bob.balance, 1.0 ether);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
