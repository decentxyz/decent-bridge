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
    bool public gasCurrencyisEth; // for chains that use ETH as gas currency

    mapping(uint16 => address) public destinationBridges;
    mapping(uint16 => address) public destinationDcntEth;

    constructor(address payable _wethAddress, bool gasIsEth) {
        weth = WETH(_wethAddress);
        gasCurrencyisEth = gasIsEth;
    }

    modifier onlyEthChain() {
        require(gasCurrencyisEth, "Gas currency is not ETH");
        _;
    }

    modifier onlyIfWeHaveEnoughReserves(uint256 amount) {
        require(weth.balanceOf(address(this)) > amount, "not enough reserves");
        _;
    }

    modifier userDepositing(uint256 amount) {
        balanceOf[msg.sender] += amount;
        _;
    }

    modifier userIsWithdrawing(uint256 amount) {
        uint256 balance = balanceOf[msg.sender];
        require(balance >= amount, "not enough balance");
        _;
        balanceOf[msg.sender] -= amount;
    }

    function deployDcntEth(address lzEndpoint) public {
        dcntEth = new DcntEth(lzEndpoint);
    }

    function registerDcntEth(address _addr) public {
        dcntEth = DcntEth(_addr);
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
        bytes memory _payload = abi.encode(msg.sender, _toAddress);
        uint256 GAS_FOR_RELAY = 100000;
        uint256 gasAmount = GAS_FOR_RELAY + _dstGasForCall;
        bytes memory _adapterParams = abi.encodePacked(
            PT_SEND_AND_CALL,
            gasAmount
        );
        address _dstBridge = destinationBridges[_dstChainId];
        bytes32 destinationBridge = bytes32(abi.encode(_dstBridge));
        return (destinationBridge, _adapterParams, _payload);
    }

    function estimateSendAndCallFee(
        uint16 _dstChainId,
        address _toAddress,
        uint _amount,
        uint64 _dstGasForCall
    ) public view returns (uint nativeFee, uint zroFee) {
        (
            bytes32 destinationBridge,
            bytes memory adapterParams,
            bytes memory _payload
        ) = getCallParams(_toAddress, _dstChainId, _dstGasForCall);
        return
            dcntEth.estimateSendAndCallFee(
                _dstChainId,
                destinationBridge,
                _amount,
                _payload,
                _dstGasForCall,
                false, // useZero
                adapterParams // Relayer adapter parameters
                // contains packet type (send and call in this case) and gasAmount
            );
    }

    function bridgeEth(
        uint16 _dstChainId,
        address _toAddress,
        uint _amount,
        uint64 _dstGasForCall
    ) public payable {
        (
            bytes32 destinationBridge,
            bytes memory adapterParams,
            bytes memory payload
        ) = getCallParams(_toAddress, _dstChainId, _dstGasForCall);

        ICommonOFT.LzCallParams memory callParams = ICommonOFT.LzCallParams({
            refundAddress: payable(msg.sender),
            zroPaymentAddress: address(0x0),
            adapterParams: adapterParams
        });

        uint gasValue;
        if (gasCurrencyisEth) {
            weth.deposit{value: _amount}();
            gasValue = msg.value - _amount;
        } else {
            weth.transferFrom(msg.sender, address(this), _amount);
            gasValue = msg.value;
        }

        dcntEth.sendAndCall{value: gasValue}(
            address(this), // from address that has dcntEth (so DecentRouter)
            _dstChainId,
            destinationBridge, // toAddress
            _amount, // amount
            payload, //payload (will have recipients address)
            _dstGasForCall, // dstGasForCall
            callParams // refundAddress, zroPaymentAddress, adapterParams
        );
    }

    event ReceivedDecentEth(
        uint16 _srcChainId,
        address from,
        address _to,
        uint amount
    );

    function onOFTReceived(
        uint16 _srcChainId,
        bytes calldata,
        uint64,
        bytes32,
        uint _amount,
        bytes memory _payload
    ) external override {
        (address from, address _to) = abi.decode(_payload, (address, address));
        emit ReceivedDecentEth(_srcChainId, from, _to, _amount);

        if (weth.balanceOf(address(this)) < _amount) {
            dcntEth.transfer(_to, _amount);
            return;
        }

        if (gasCurrencyisEth) {
            weth.withdraw(_amount);
            payable(_to).transfer(_amount);
        } else {
            weth.transfer(_to, _amount);
        }
    }

    function redeemEth(
        uint256 amount
    ) public onlyIfWeHaveEnoughReserves(amount) {
        dcntEth.transferFrom(msg.sender, address(this), amount);
        weth.withdraw(amount);
        payable(msg.sender).transfer(amount);
    }

    function redeemWeth(
        uint256 amount
    ) public onlyIfWeHaveEnoughReserves(amount) {
        dcntEth.transferFrom(msg.sender, address(this), amount);
        weth.transfer(msg.sender, amount);
    }

    mapping(address => uint256) public balanceOf;

    function addLiquidityEth()
        public
        payable
        onlyEthChain
        userDepositing(msg.value)
    {
        weth.deposit{value: msg.value}();
        dcntEth.mint(address(this), msg.value);
    }

    function removeLiquidityEth(
        uint256 amount
    ) public onlyEthChain userIsWithdrawing(amount) {
        dcntEth.burn(address(this), amount);
        weth.withdraw(amount);
        payable(msg.sender).transfer(amount);
    }

    function addLiquidityWeth(
        uint256 amount
    ) public payable userDepositing(amount) {
        weth.transferFrom(msg.sender, address(this), amount);
        dcntEth.mint(address(this), amount);
    }

    function removeLiquidityWeth(
        uint256 amount
    ) public userIsWithdrawing(amount) {
        dcntEth.burn(address(this), amount);
        weth.transfer(msg.sender, amount);
    }

    receive() external payable {}

    fallback() external payable {}
}
