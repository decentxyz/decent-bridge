// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test} from "forge-std/Test.sol";
import {DecentEthRouter} from "src/DecentEthRouter.sol";
import {DcntEth} from "src/DcntEth.sol";

contract CommonRouterSetup is Test {
    DecentEthRouter router;
    DcntEth dcntEth;
    uint MIN_DST_GAS = 100000;

    address alice = address(0xbeef);
    address bob = address(0xfeeb);

    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint _minDstGas);
    uint16 public constant PT_SEND_AND_CALL = 1;

    function setUpDstRouter()
        internal
        returns (
            uint16 dstLzOpId,
            DecentEthRouter dstRouter,
            DcntEth dstDcntEth
        )
    {
        uint16 dstLzOpId = 111;
        DecentEthRouter dstRouter = DecentEthRouter(payable(address(0xbeef)));
        DcntEth dstDcntEth = DcntEth(payable(address(0xdeed)));
        bytes memory path = abi.encodePacked(dstDcntEth, address(dcntEth));
        uint16 PT_SEND_AND_CALL = router.PT_SEND_AND_CALL();
        vm.expectEmit(true, true, true, true);
        emit SetTrustedRemote(dstLzOpId, path);
        vm.expectEmit(true, true, true, true);
        emit SetMinDstGas(dstLzOpId, PT_SEND_AND_CALL, MIN_DST_GAS);
        router.addDestinationBridge(
            dstLzOpId,
            address(dstRouter), // you're sending to this
            address(dstDcntEth), // this is who you're approving
            MIN_DST_GAS
        );
        return (dstLzOpId, dstRouter, dstDcntEth);
    }

    uint64 DST_GAS_FOR_CALL = 120000;

    function attemptBridge(
        uint amount,
        uint16 dstLzOpId,
        DecentEthRouter dstRouter,
        DcntEth dstDcntEth
    ) internal {
        address toAddress = msg.sender;

        (uint nativeFee, uint zroFee) = router.estimateSendAndCallFee(
            dstLzOpId,
            toAddress,
            amount,
            DST_GAS_FOR_CALL
        );

        router.bridgeEth{value: amount + nativeFee + zroFee}(
            dstLzOpId,
            toAddress,
            amount,
            DST_GAS_FOR_CALL
        );
    }

    function setupAndBridge(uint amount) internal {
        (
            uint16 dstLzOpId,
            DecentEthRouter dstRouter,
            DcntEth dstDcntEth
        ) = setUpDstRouter();

        attemptBridge(amount, dstLzOpId, dstRouter, dstDcntEth);
    }

    event ReceivedDecentEth(
        uint16 _srcChainId,
        address from,
        address _to,
        uint amount
    );

    // Emulating the reception of dcntEth from the bridge;
    function receiveSomeEth(
        address _from,
        address _to,
        uint256 amount
    ) internal {
        uint16 srcChainId = 69;
        uint64 _nonce = 0;
        bytes memory _srcAddress = abi.encode(address(0xdeadbeef));
        bytes32 from = bytes32(abi.encode(_from)); // bytes32(bytes(bob));
        bytes memory _payload = abi.encode(_to);

        vm.startPrank(address(router));
        dcntEth.mint(address(router), amount);

        vm.expectEmit(true, true, true, true);
        emit ReceivedDecentEth(srcChainId, _from, _to, amount);
        router.onOFTReceived(
            srcChainId,
            _srcAddress,
            _nonce,
            from,
            amount,
            _payload
        );
    }
}
