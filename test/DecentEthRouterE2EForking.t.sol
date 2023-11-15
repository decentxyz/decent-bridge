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
import {ILayerZeroEndpoint} from "LayerZero/interfaces/ILayerZeroEndpoint.sol";

abstract contract Endpoint is ILayerZeroEndpoint {
    address public defaultReceiveLibraryAddress;
}

contract OpenDcntEth is DcntEth {
    constructor(address _layerZeroEndpoint) DcntEth(_layerZeroEndpoint) {}

    function encodeSendAndCallPayload(
        address _from,
        address _toAddress,
        uint _amount,
        bytes memory _payload,
        uint64 _dstGasForCall
    ) external view virtual returns (bytes memory) {
        return
            _encodeSendAndCallPayload(
                _from,
                bytes32(abi.encode(_toAddress)),
                _ld2sd(_amount),
                _payload,
                _dstGasForCall
            );
    }
}

contract DecentEthRouterEthChainTest is CommonRouterSetup {
    string firstChain = "arbitrum";
    string secondChain = "optimism";

    WETH firstWeth = WETH(payable(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1));
    WETH secondWeth = WETH(payable(0x4200000000000000000000000000000000000006));

    uint16 firstLzId = 110;
    uint16 secondLzId = 110;

    Endpoint firstLzEndpoint =
        Endpoint(0x3c2269811836af69497E5F486A85D7316753cf62);
    Endpoint secondLzEndpoint =
        Endpoint(0x3c2269811836af69497E5F486A85D7316753cf62);

    DecentEthRouter firstRouter;
    DecentEthRouter secondRouter;

    uint256 firstFork;
    uint256 secondFork;

    OpenDcntEth firstDcntEth;
    OpenDcntEth secondDcntEth;

    bool firstGasIsEth = true;
    bool secondGasIsEth = true;

    function forkAndDeploy(
        string memory chain,
        address payable weth,
        ILayerZeroEndpoint lzEndpoint,
        bool gasIsEth,
        uint256 liquidity
    ) internal returns (uint256, DecentEthRouter, OpenDcntEth) {
        uint256 fork = vm.createSelectFork(chain);
        DecentEthRouter router = new DecentEthRouter(weth, gasIsEth);
        OpenDcntEth dcntEth = new OpenDcntEth(address(lzEndpoint));
        router.registerDcntEth(address(dcntEth));
        dcntEth.transferOwnership(address(router));
        router.addLiquidityEth{value: liquidity}();
        return (fork, router, dcntEth);
    }

    function setupFirstRouter() internal {
        (firstFork, firstRouter, firstDcntEth) = forkAndDeploy(
            firstChain,
            payable(address(firstWeth)),
            firstLzEndpoint,
            firstGasIsEth,
            10 ether
        );
    }

    function setupSecondRouter() internal {
        (secondFork, secondRouter, secondDcntEth) = forkAndDeploy(
            secondChain,
            payable(address(secondWeth)),
            secondLzEndpoint,
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

    function receiveOFT(
        address fromAddress,
        address toAddress,
        OpenDcntEth srcDcntEth,
        OpenDcntEth dstDcntEth,
        DecentEthRouter srcRouter,
        DecentEthRouter dstRouter,
        Endpoint dstLzEndpoint,
        uint256 amount,
        uint256 dstFork,
        uint16 srcLzId,
        bool receiveEth
    ) public {
        bytes memory oftPayload = abi.encode(
            MT_ETH_TRANSFER,
            fromAddress,
            toAddress,
            receiveEth,
            ""
        );

        bytes memory lzPayload = firstDcntEth.encodeSendAndCallPayload(
            address(srcRouter), // first router (has decent eth)
            address(dstRouter), // to address (has decent eth)
            amount,
            oftPayload, // will have the recipients address
            DST_GAS_FOR_CALL
        );

        vm.selectFork(dstFork);

        uint64 nonce = dstLzEndpoint.getInboundNonce(
            srcLzId,
            abi.encode(address(srcDcntEth))
        );

        address defaultLibAddress = dstLzEndpoint
            .defaultReceiveLibraryAddress();

        vm.deal(defaultLibAddress, 1 ether);
        vm.prank(defaultLibAddress);
        secondLzEndpoint.receivePayload(
            srcLzId, // src chain id
            abi.encodePacked(address(srcDcntEth), address(dstDcntEth)), // src address
            address(dstDcntEth), // dst address
            nonce + 1, // nonce
            DST_GAS_FOR_CALL * 2, // gas limit
            lzPayload // payload
        );
    }

    function testBridgeEndToEndFromSourceToDestination() public {
        vm.selectFork(firstFork);
        uint amount = 1 ether;

        vm.deal(alice, 4 ether);
        vm.prank(alice);
        (uint nativeFee, uint zroFee) = attemptBridge(
            firstRouter,
            alice,
            bob,
            amount,
            secondLzId
        );
        assertEq(firstWeth.balanceOf(address(firstRouter)), 10 ether + amount);
        assertEq(alice.balance, 3 ether - nativeFee - zroFee); // alice sent her money

        receiveOFT(
            alice,
            bob,
            firstDcntEth,
            secondDcntEth,
            firstRouter,
            secondRouter,
            firstLzEndpoint,
            amount,
            secondFork,
            firstLzId,
            true
        );

        assertEq(
            secondWeth.balanceOf(address(secondRouter)),
            10 ether - amount
        );

        assertEq(bob.balance, amount); // bob received his money
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
