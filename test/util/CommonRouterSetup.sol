// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {DecentEthRouter} from "src/DecentEthRouter.sol";
import {DcntEth} from "src/DcntEth.sol";

contract CommonRouterSetup is Test {
    uint8 public constant MT_ETH_TRANSFER = 0;
    uint8 public constant MT_ETH_TRANSFER_WITH_PAYLOAD = 1;
    DecentEthRouter router;
    DcntEth dcntEth;
    uint MIN_DST_GAS = 100000;

    address alice = address(0xbeef);
    address bob = address(0xfeeb);

    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint _minDstGas);
    uint16 public constant PT_SEND_AND_CALL = 1;

    uint64 DST_GAS_FOR_CALL = 120000;

    event ReceivedDecentEth(
        uint8 msgType,
        uint16 _srcChainId,
        address from,
        address _to,
        uint amount,
        bytes payload
    );

    // Emulating the reception of dcntEth from the bridge;
    function receiveSomeEth(
        address _from,
        address _to,
        uint256 amount,
        bool deliverEth
    ) internal {
        uint16 srcChainId = 69;
        uint64 _nonce = 0;
        bytes memory _srcAddress = abi.encode(address(0xdeadbeef));
        bytes32 from = bytes32(abi.encode(_from)); // bytes32(bytes(bob));
        bytes memory _payload = abi.encode(
            MT_ETH_TRANSFER,
            _from,
            _to,
            _from,
            deliverEth,
            ""
        );

        vm.startPrank(address(router));
        dcntEth.mint(address(router), amount);

        vm.expectEmit(true, true, true, true);
        emit ReceivedDecentEth(
            MT_ETH_TRANSFER,
            srcChainId,
            _from,
            _to,
            amount,
            ""
        );
        vm.startPrank(address(dcntEth));
        router.onOFTReceived(
            srcChainId,
            _srcAddress,
            _nonce,
            from,
            amount,
            _payload
        );
        vm.stopPrank();
    }
}
