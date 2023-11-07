// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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
        uint maticFork = vm.createSelectFork("polygon");
        assertEq(vm.activeFork(), maticFork);
        weth = new BridgedWeth();
        router = new DecentEthRouter(payable(address(weth)), isGasEth);
        dcntEth = new DcntEth(lzEndpointPolygon);
        router.registerDcntEth(address(dcntEth));
        dcntEth.transferOwnership(address(router));
    }

    function addLiquidity(uint amount) internal {
        weth.mint(address(this), amount);
        weth.approve(address(router), amount);
        router.addLiquidityWeth(amount);
    }

    function testBridgeEthShouldAttemptToBridge() public {
        addLiquidity(20);

        (uint16 dstLzOpId, , ) = setUpDstRouter();

        uint amount = 10;
        address toAddress = msg.sender;

        (uint nativeFee, uint zroFee) = router.estimateSendAndCallFee(
            MT_ETH_TRANSFER,
            dstLzOpId,
            toAddress,
            amount,
            DST_GAS_FOR_CALL,
            ""
        );

        weth.mint(address(this), amount);
        weth.approve(address(router), amount);

        router.bridgeWeth{value: nativeFee + zroFee}(
            dstLzOpId,
            toAddress,
            amount,
            DST_GAS_FOR_CALL
        );

        assertEq(weth.balanceOf(address(router)), 30); // 20 + 10 bridged
        assertEq(dcntEth.balanceOf(address(router)), 10); // 20 - 10 bridged
        assertEq(address(router).balance, 0);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
