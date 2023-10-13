// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WETH} from "solmate/tokens/WETH.sol";
import {DcntEth} from "./DcntEth.sol";
import {ICommonOFT} from "solidity-examples/token/oft/v2/interfaces/ICommonOFT.sol";

contract DecentEthRouter {
    WETH public weth;
    DcntEth public dcntEth;
    mapping(uint16 => address) public destinationBridges;

    constructor(address payable _wethAddress) {
        weth = WETH(_wethAddress);
    }

    function deployDcntEth(address lzEndpoint) public {
        dcntEth = new DcntEth(lzEndpoint);
    }

    function addDestinationBridge(
        uint16 _dstChainId,
        address _bridgeAddress
    ) public {
        destinationBridges[_dstChainId] = _bridgeAddress;
    }

    function bridgeEth(
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint _amount
    ) public payable {
        ICommonOFT.LzCallParams memory callParams = ICommonOFT.LzCallParams({
            refundAddress: payable(msg.sender),
            zroPaymentAddress: address(0x0),
            adapterParams: abi.encodePacked(_toAddress)
        });

        bytes32 destinationBridge = bytes32(
            abi.encodePacked(destinationBridges[_dstChainId])
        );

        bytes memory payload = abi.encodePacked(
            this.receiveEth,
            _toAddress,
            _amount
        );

        dcntEth.sendAndCall(
            address(this),
            _dstChainId,
            destinationBridge,
            msg.value, // amount
            payload, //payload
            21000, // dstGasForCall
            callParams
        );
    }

    function receiveEth(address payable _to, uint _amount) public {
        weth.withdraw(_amount);
        _to.transfer(_amount);
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
}
