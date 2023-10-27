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
    string firstChain = "arbitrum";
    string secondChain = "optimism";

    WETH firstWeth = WETH(payable(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1));
    WETH secondWeth = WETH(payable(0x4200000000000000000000000000000000000006));

    uint16 firstLzId = 110;
    uint16 secondLzId = 110;

    address firstLzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address secondLzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;

    DecentEthRouter firstRouter;
    DecentEthRouter secondRouter;

    uint256 firstFork;
    uint256 secondFork;

    DcntEth firstDcntEth;
    DcntEth secondDcntEth;

    bool firstGasIsEth = true;
    bool secondGasIsEth = true;

    function forkAndDeploy(
        string memory chain,
        address payable weth,
        bool gasIsEth,
        uint256 liquidity
    ) internal returns (uint256, DecentEthRouter, DcntEth) {
        uint256 fork = vm.createSelectFork(chain);
        DecentEthRouter router = new DecentEthRouter(weth, gasIsEth);
        router.deployDcntEth(firstLzEndpoint);
        router.addLiquidityEth{value: liquidity}();
        DcntEth dcntEth = DcntEth(router.dcntEth());
        return (fork, router, dcntEth);
    }

    function setupFirstRouter() internal {
        (firstFork, firstRouter, firstDcntEth) = forkAndDeploy(
            firstChain,
            payable(address(firstWeth)),
            firstGasIsEth,
            10 ether
        );
    }

    function setupSecondRouter() internal {
        (secondFork, secondRouter, secondDcntEth) = forkAndDeploy(
            secondChain,
            payable(address(secondWeth)),
            secondGasIsEth,
            10 ether
        );
    }

    function addDestination(
        DecentEthRouter router,
        uint16 dstChainId,
        address dstRouterAddress,
        address srcDcntEth,
        address dstDcntEth
    ) internal {
        bytes memory path = abi.encodePacked(dstDcntEth, srcDcntEth);
        vm.expectEmit(true, true, true, true);
        emit SetTrustedRemote(dstChainId, path);
        vm.expectEmit(true, true, true, true);
        emit SetMinDstGas(dstChainId, PT_SEND_AND_CALL, MIN_DST_GAS);
        router.addDestinationBridge(
            dstChainId,
            dstRouterAddress,
            dstDcntEth,
            MIN_DST_GAS
        );
    }

    function setUp() public {
        setupFirstRouter();
        setupSecondRouter();
        vm.selectFork(firstFork);
        addDestination(
            firstRouter,
            secondLzId,
            address(secondRouter),
            address(firstDcntEth),
            address(secondDcntEth)
        );
        vm.selectFork(secondFork);
        addDestination(
            secondRouter,
            firstLzId,
            address(firstRouter),
            address(secondDcntEth),
            address(firstDcntEth)
        );
    }

    function testDoNothingYet() public {
        vm.selectFork(firstFork);
        attemptBridge(firstRouter, msg.sender, 1 ether, secondLzId);
        assertEq(firstWeth.balanceOf(address(firstRouter)), 11 ether);

        vm.selectFork(secondFork);



    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
