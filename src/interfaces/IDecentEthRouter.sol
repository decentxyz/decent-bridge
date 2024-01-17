pragma solidity ^0.8.0;

interface IDecentEthRouter {

    event ReceivedDecentEth(
        uint8 msgType,
        uint16 _srcChainId,
        address from,
        address _to,
        uint amount,
        bytes payload
    );

    function MT_ETH_TRANSFER() external view returns (uint8);

    function MT_ETH_TRANSFER_WITH_PAYLOAD() external view returns (uint8);

    function registerDcntEth(address _addr) external;

    function addDestinationBridge(
        uint16 _dstChainId,
        address _routerAddress
    ) external;

    function estimateSendAndCallFee(
        uint8 msgType,
        uint16 _dstChainId,
        address _toAddress,
        uint _amount,
        uint64 _dstGasForCall,
        bool deliverEth,
        bytes memory payload
    ) external view returns (uint nativeFee, uint zroFee);

    function bridgeWithPayload(
        uint16 _dstChainId,
        address _toAddress,
        uint _amount,
        bool deliverEth,
        uint64 _dstGasForCall,
        bytes memory additionalPayload
    ) external payable;

    function bridge(
        uint16 _dstChainId,
        address _toAddress,
        uint _amount,
        uint64 _dstGasForCall,
        bool deliverEth // if false, delivers WETH
    ) external payable;

    function redeemEth(uint256 amount) external;

    function redeemWeth(uint256 amount) external;

    function addLiquidityEth() external payable;

    function removeLiquidityEth(uint256 amount) external;

    function addLiquidityWeth(uint256 amount) external payable;

    function removeLiquidityWeth(uint256 amount) external;
}
