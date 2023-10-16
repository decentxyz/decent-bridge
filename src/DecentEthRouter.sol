// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WETH} from "solmate/tokens/WETH.sol";
import {DcntEth} from "./DcntEth.sol";
import {ICommonOFT} from "solidity-examples/token/oft/v2/interfaces/ICommonOFT.sol";
import {IOFTReceiverV2} from "solidity-examples/token/oft/v2/interfaces/IOFTReceiverV2.sol";

contract DecentEthRouter is IOFTReceiverV2 {
    WETH public weth;
    DcntEth public dcntEth;

    uint16 public constant PT_SEND = 0;
    uint16 public constant PT_SEND_AND_CALL = 1;

    mapping(uint16 => address) public destinationBridges;
    mapping(uint16 => address) public destinationDcntEth;

    constructor(address payable _wethAddress) {
        weth = WETH(_wethAddress);
    }

    function deployDcntEth(address lzEndpoint) public {
        dcntEth = new DcntEth(lzEndpoint);
    }

    function addDestinationBridge(
        uint16 _dstChainId,
        address _routerAddress,
        address dstDcntEth,
        uint _minDstGas
    ) public {
        destinationBridges[_dstChainId] = _routerAddress;
        destinationDcntEth[_dstChainId] = dstDcntEth;
        dcntEth.setTrustedRemote(
            _dstChainId,
            abi.encodePacked(dstDcntEth, address(dcntEth))
        );
        dcntEth.setMinDstGas(_dstChainId, PT_SEND_AND_CALL, _minDstGas);
    }

    function getCallParams(
        address _toAddress,
        uint16 _dstChainId,
        uint _amount,
        uint64 _dstGasForCall
    )
        internal
        view
        returns (
            bytes32 destBridge,
            bytes memory adapterParams,
            bytes memory payload
        )
    {
        bytes memory payload = abi.encode(0);
        uint256 GAS_FOR_RELAY = 100000;
        uint256 gasAmount = GAS_FOR_RELAY + _dstGasForCall;
        bytes memory adapterParams = abi.encodePacked(
            PT_SEND_AND_CALL,
            gasAmount
        );
        address _dstBridge = destinationBridges[_dstChainId];
        bytes32 destinationBridge = bytes32(abi.encode(_dstBridge));
        return (destinationBridge, adapterParams, payload);
    }

    function estimateSendAndCallFee(
        uint16 _dstChainId,
        address _toAddress,
        uint _amount,
        uint64 _dstGasForCall,
        bytes memory payload
    ) public view returns (uint nativeFee, uint zroFee) {
        (
            bytes32 destinationBridge,
            bytes memory adapterParams,
            bytes memory _payload
        ) = getCallParams(_toAddress, _dstChainId, _amount, _dstGasForCall);
        return
            dcntEth.estimateSendAndCallFee(
                _dstChainId,
                destinationBridge,
                _amount,
                payload,
                _dstGasForCall,
                false, // useZero
                adapterParams // relayer adapter parameters
            );
    }

    function bridgeEth(
        uint16 _dstChainId,
        address _toAddress,
        uint _amount,
        uint64 _dstGasForCall,
        bytes memory payload
    ) public payable {
        (
            bytes32 destinationBridge,
            bytes memory adapterParams,
            bytes memory _payload
        ) = getCallParams(_toAddress, _dstChainId, _amount, _dstGasForCall);

        ICommonOFT.LzCallParams memory callParams = ICommonOFT.LzCallParams({
            refundAddress: payable(msg.sender),
            zroPaymentAddress: address(0x0),
            adapterParams: adapterParams
        });

        weth.deposit{value: _amount}();
        dcntEth.sendAndCall{value: msg.value - _amount}(
            address(this), // from
            _dstChainId,
            destinationBridge, // toAddress
            _amount, // amount
            payload, //payload
            _dstGasForCall, // dstGasForCall
            callParams
        );
    }

    event ReceivedDecentEth(uint amount, address _to);

    function onOFTReceived(
        uint16 _srcChainId,
        bytes calldata,
        uint64,
        bytes32 _from,
        uint _amount,
        bytes memory _payload
    ) external override {
        address _to = abi.decode(_payload, (address));
        emit ReceivedDecentEth(_amount, _to);
        weth.withdraw(_amount);
        payable(_to).transfer(_amount);
    }

    function addLiquidityEth() public payable {
        weth.deposit{value: msg.value}();
        dcntEth.mint(address(this), msg.value);
    }

    function removeLiquidityEth(uint256 amount) public {
        dcntEth.burn(address(this), amount);
        weth.withdraw(amount);
        payable(msg.sender).transfer(amount);
    }

    function addLiquidityWeth(uint256 amount) public payable {
        weth.transferFrom(msg.sender, address(this), amount);
        dcntEth.mint(address(this), amount);
    }

    function removeLiquidityWeth(uint256 amount) public {
        dcntEth.burn(address(this), amount);
        weth.transfer(msg.sender, amount);
    }

    receive() external payable {}

    fallback() external payable {}
}
