// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {DecentBridgeExecutor} from "../src/DecentBridgeExecutor.sol";
import {Test, console, console2} from "forge-std/Test.sol";
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {OFTV2} from "solidity-examples/token/oft/v2/OFTV2.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {DecentEthRouter} from "src/DecentEthRouter.sol";
import {DcntEth} from "src/DcntEth.sol";
import {CommonRouterSetup} from "test/util/CommonRouterSetup.sol";

contract BridgedWeth is ERC20("Wrapped Ether", "WETH", 18) {
    function mint(address to, uint amount) external {
        _mint(to, amount);
    }
}

contract DecentEthRouterNonEthChainTest is CommonRouterSetup {
    BridgedWeth weth;
    address lzEndpointPolygon = 0x3c2269811836af69497E5F486A85D7316753cf62;
    bool isGasEth = false;

    function setUp() public {
        weth = new BridgedWeth();
        DecentBridgeExecutor executor = new DecentBridgeExecutor(
            payable(address(weth)),
            isGasEth
        );
        router = new DecentEthRouter(
            payable(address(weth)),
            isGasEth,
            address(executor)
        );
        executor.transferOwnership(address(router));
        dcntEth = new DcntEth(lzEndpointPolygon);
        router.registerDcntEth(address(dcntEth));
        dcntEth.setRouter(address(router));
    }

    function testAddLiquidity() public {
        uint amount = 10;
        vm.expectRevert("Gas currency is not ETH");
        router.addLiquidityEth{value: amount}();
    }

    function testRemoveLiquidity() public {
        uint amount = 10;
        vm.expectRevert("Gas currency is not ETH");
        router.removeLiquidityEth(amount);
    }

    function addLiquidity(uint amount) internal {
        weth.mint(address(this), amount);
        weth.approve(address(router), amount);
        router.addLiquidityWeth(amount);
    }

    function testAddLiquidityWeth() public {
        uint amount = 10;
        addLiquidity(amount);
        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.balanceOf(address(router)), amount);
    }

    function testRemoveLiquidityWeth() public {
        uint amount = 10;
        addLiquidity(amount);
        router.removeLiquidityWeth(3);
        assertEq(weth.balanceOf(address(this)), 3);
        assertEq(weth.balanceOf(address(router)), 7);
    }

    function testUserShouldBeGivenWethIfRouterHasBalance() public {
        addLiquidity(2 ether);

        receiveSomeEth(
            bob, // from
            alice, // to,
            0.69 ether, // amt received,
            false // deliver weth
        );

        assertEq(dcntEth.balanceOf(alice), 0);

        assertEq(dcntEth.balanceOf(address(router)), 2.69 ether);

        assertEq(alice.balance, 0 ether);
        assertEq(weth.balanceOf(alice), 0.69 ether);
        assertEq(weth.balanceOf(address(router)), 2 ether - 0.69 ether);
    }

    function testShouldHandlePermissionedWithdrawals() public {
        address alice = address(0xbeef);
        address bob = address(0xfeeb);
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        weth.mint(alice, 1 ether);
        weth.mint(bob, 1 ether);

        vm.startPrank(alice);
        weth.approve(address(router), 0.1 ether);
        router.addLiquidityWeth(0.1 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        weth.approve(address(router), 0.1 ether);
        router.addLiquidityWeth(0.05 ether);
        vm.stopPrank();

        assertEq(router.balanceOf(alice), 0.1 ether);
        assertEq(router.balanceOf(bob), 0.05 ether);

        vm.prank(alice);
        router.removeLiquidityWeth(0.01 ether);
        assertEq(router.balanceOf(alice), 0.09 ether);

        vm.prank(bob);
        vm.expectRevert("not enough balance");
        router.removeLiquidityWeth(0.050001 ether);

        assertEq(weth.balanceOf(bob), 0.95 ether);
        vm.prank(bob);
        router.removeLiquidityWeth(0.05 ether);
        assertEq(router.balanceOf(bob), 0);
        assertEq(weth.balanceOf(bob), 1 ether);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
