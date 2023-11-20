// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WETH} from "solmate/tokens/WETH.sol";
import {DcntEth} from "./DcntEth.sol";
import {ICommonOFT} from "solidity-examples/token/oft/v2/interfaces/ICommonOFT.sol";
import {IOFTReceiverV2} from "solidity-examples/token/oft/v2/interfaces/IOFTReceiverV2.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {Executor} from "./Executor.sol";

contract DecentEthRouter is IOFTReceiverV2, Owned {
    WETH public weth;
    DcntEth public dcntEth;
    Executor public executor;

    uint8 public constant MT_ETH_TRANSFER = 0;
    uint8 public constant MT_ETH_TRANSFER_WITH_PAYLOAD = 1;

    uint16 public constant PT_SEND_AND_CALL = 1;

    bool public gasCurrencyIsEth; // for chains that use ETH as gas currency

    mapping(uint16 => address) public destinationBridges;

    constructor(
        address payable _wethAddress,
        bool gasIsEth,
        address _executor
    ) Owned(msg.sender) {
        weth = WETH(_wethAddress);
        gasCurrencyIsEth = gasIsEth;
        executor = Executor(payable(_executor));
    }

    modifier onlyEthChain() {
        require(gasCurrencyIsEth, "Gas currency is not ETH");
        _;
    }

    modifier onlyLzApp() {
        require(
            address(dcntEth) == msg.sender,
            "DecentEthRouter: only lz App can call"
        );
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

    function registerDcntEth(address _addr) public onlyOwner {
        dcntEth = DcntEth(_addr);
    }

    function addDestinationBridge(
        uint16 _dstChainId,
        address _routerAddress,
        address dstDcntEth,
        uint _minDstGas
    ) public onlyOwner {
        destinationBridges[_dstChainId] = _routerAddress;
        dcntEth.setTrustedRemote(
            _dstChainId,
            abi.encodePacked(dstDcntEth, address(dcntEth))
        );
        dcntEth.setMinDstGas(_dstChainId, PT_SEND_AND_CALL, _minDstGas);
    }

    function _getCallParams(
        uint8 msgType,
        address _toAddress,
        uint16 _dstChainId,
        uint64 _dstGasForCall,
        bool deliverEth,
        bytes memory additionalPayload
    )
        private
        view
        returns (
            bytes32 destBridge,
            bytes memory adapterParams,
            bytes memory payload
        )
    {
        uint256 GAS_FOR_RELAY = 100000;
        uint256 gasAmount = GAS_FOR_RELAY + _dstGasForCall;
        adapterParams = abi.encodePacked(PT_SEND_AND_CALL, gasAmount);
        destBridge = bytes32(abi.encode(destinationBridges[_dstChainId]));
        if (msgType == MT_ETH_TRANSFER) {
            payload = abi.encode(msgType, msg.sender, _toAddress, deliverEth);
        } else {
            payload = abi.encode(
                msgType,
                msg.sender,
                _toAddress,
                deliverEth,
                additionalPayload
            );
        }
    }

    function estimateSendAndCallFee(
        uint8 msgType,
        uint16 _dstChainId,
        address _toAddress,
        uint _amount,
        uint64 _dstGasForCall,
        bool deliverEth,
        bytes memory payload
    ) public view returns (uint nativeFee, uint zroFee) {
        (
            bytes32 destinationBridge,
            bytes memory adapterParams,
            bytes memory _payload
        ) = _getCallParams(
                msgType,
                _toAddress,
                _dstChainId,
                _dstGasForCall,
                deliverEth,
                payload
            );

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

    function _bridgeWithPayload(
        uint8 msgType,
        uint16 _dstChainId,
        address _toAddress,
        uint _amount,
        uint64 _dstGasForCall,
        bytes memory additionalPayload,
        bool deliverEth
    ) internal {
        (
            bytes32 destinationBridge,
            bytes memory adapterParams,
            bytes memory payload
        ) = _getCallParams(
                msgType,
                _toAddress,
                _dstChainId,
                _dstGasForCall,
                deliverEth,
                additionalPayload
            );

        ICommonOFT.LzCallParams memory callParams = ICommonOFT.LzCallParams({
            refundAddress: payable(msg.sender),
            zroPaymentAddress: address(0x0),
            adapterParams: adapterParams
        });

        uint gasValue;
        if (gasCurrencyIsEth) {
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

    function bridgeWithPayload(
        uint16 _dstChainId,
        address _toAddress,
        uint _amount,
        bool deliverEth,
        uint64 _dstGasForCall,
        bytes memory additionalPayload
    ) public payable {
        return
            _bridgeWithPayload(
                MT_ETH_TRANSFER_WITH_PAYLOAD,
                _dstChainId,
                _toAddress,
                _amount,
                _dstGasForCall,
                additionalPayload,
                deliverEth
            );
    }

    function bridge(
        uint16 _dstChainId,
        address _toAddress,
        uint _amount,
        uint64 _dstGasForCall,
        bool deliverEth // if false, delivers WETH
    ) public payable {
        _bridgeWithPayload(
            MT_ETH_TRANSFER,
            _dstChainId,
            _toAddress,
            _amount,
            _dstGasForCall,
            bytes(""),
            deliverEth
        );
    }

    event ReceivedDecentEth(
        uint8 msgType,
        uint16 _srcChainId,
        address from,
        address _to,
        uint amount,
        bytes payload
    );

    function onOFTReceived(
        uint16 _srcChainId,
        bytes calldata,
        uint64,
        bytes32,
        uint _amount,
        bytes memory _payload
    ) external override onlyLzApp {
        (uint8 msgType, address _from, address _to, bool deliverEth) = abi
            .decode(_payload, (uint8, address, address, bool));

        bytes memory callPayload = "";

        if (msgType == MT_ETH_TRANSFER_WITH_PAYLOAD) {
            (, , , , callPayload) = abi.decode(
                _payload,
                (uint8, address, address, bool, bytes)
            );
        }

        emit ReceivedDecentEth(
            msgType,
            _srcChainId,
            _from,
            _to,
            _amount,
            callPayload
        );

        if (weth.balanceOf(address(this)) < _amount) {
            dcntEth.transfer(_to, _amount);
            return;
        }

        if (msgType == MT_ETH_TRANSFER) {
            if (!gasCurrencyIsEth || !deliverEth) {
                weth.transfer(_to, _amount);
            } else {
                weth.withdraw(_amount);
                payable(_to).transfer(_amount);
            }
        } else {
            weth.approve(address(executor), _amount);
            executor.execute(_from, _to, deliverEth, _amount, callPayload);
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
