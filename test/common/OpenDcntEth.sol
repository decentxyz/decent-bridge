pragma solidity ^0.8.0;

import {console2} from "forge-std/console2.sol";
import {DcntEth} from "../../src/DcntEth.sol";

contract OpenDcntEth is DcntEth {
    constructor(address _layerZeroEndpoint) DcntEth(_layerZeroEndpoint) {}

    function encodeSendAndCallPayload(
        address _from,
        address _toAddress,
        uint _amount,
        bytes memory _payload,
        uint64 _dstGasForCall
    ) external view virtual returns (bytes memory) {
        address from = _from;
        bytes32 toAddress = bytes32(abi.encode(_toAddress));
        uint64 amountSD = _ld2sd(_amount);
        bytes memory payload = _payload;
        uint64 dstGasForCall = _dstGasForCall;
        console2.log("from", from);
        console2.log("PT_SEND_AND_CALL", PT_SEND_AND_CALL);
        console2.log("toAddress here");
        console2.logBytes32(toAddress);
        console2.log("amountSD", amountSD);
        console2.log("our app payload down here");
        console2.logBytes(payload);
        console2.log("dstGasForCall", dstGasForCall);
        bytes memory lzPayload = _encodeSendAndCallPayload(
            from,
            toAddress,
            amountSD,
            payload,
            dstGasForCall
        );
        console2.log("lzPayload here");
        console2.logBytes(lzPayload);
        return lzPayload;
    }
}
