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
    
    error OnlyLzApp();

    error OnlyEthChain();

    error OnlyBridgeOperator();

    error NotEnoughReserves();

    error InsufficientBalance();

    function MT_ETH_TRANSFER() external view returns (uint8);

    function MT_ETH_TRANSFER_WITH_PAYLOAD() external view returns (uint8);

    /**
     * @dev Sets dcntEth to the router
     * @param _addr The address of the deployed DcntEth token
     */
    function registerDcntEth(address _addr) external;

    /**
     * @dev Adds a destination bridge for the bridge
     * @param _dstChainId The lz chainId
     * @param _routerAddress The router address on the dst chain
     */
    function addDestinationBridge(
        uint16 _dstChainId,
        address _routerAddress
    ) external;

    function estimateSendAndCallFee(
        uint8 msgType,
        uint16 _dstChainId,
        address _toAddress,
        address _refundAddress,
        uint _amount,
        uint64 _dstGasForCall,
        bool deliverEth,
        bytes memory payload
    ) external view returns (uint nativeFee, uint zroFee);

    /**
     * @param _dstChainId lz endpoint
     * @param _toAddress the destination address (i.e. dst bridge)
     * @param _refundAddress the refund address
     * @param _amount the amount being bridged
     * @param deliverEth if false, delivers WETH
     * @param _dstGasForCall the amount of dst gas
     * @param additionalPayload contains the refundAddress, zroPaymentAddress, and adapterParams
     */
    function bridgeWithPayload(
        uint16 _dstChainId,
        address _toAddress,
        address _refundAddress,
        uint _amount,
        bool deliverEth,
        uint64 _dstGasForCall,
        bytes memory additionalPayload
    ) external payable;

    /**
     * @param _dstChainId lz endpoint
     * @param _toAddress destination address
     * @param _refundAddress the address to be refunded
     * @param _amount the amount being bridge
     * @param _dstGasForCall the amount of dst gas
     * @param deliverEth if false, delivers WETH
     */
    function bridge(
        uint16 _dstChainId,
        address _toAddress,
        address _refundAddress,
        uint _amount,
        uint64 _dstGasForCall,
        bool deliverEth // if false, delivers WETH
    ) external payable;

    /**
     * @dev allows users to redeem their dcntEth for ETH
     * @param amount the amount to be redeemed
     */
    function redeemEth(uint256 amount) external;

    /**
     * @dev allows users to redeem their dcntEth for WETH
     * @param amount the amount to be redeemed
     */
    function redeemWeth(uint256 amount) external;

    /**
     * @dev adds bridge liquidity by paying ETH
     */
    function addLiquidityEth() external payable;

    /**
     * @dev withdraws a users bridge liquidity for ETH
     * @param amount the amount to be redeemed
     */
    function removeLiquidityEth(uint256 amount) external;

    /**
     * @dev adds bridge liquidity by providing WETH
     * @param amount the amount to be added
     */
    function addLiquidityWeth(uint256 amount) external payable;

    /**
     * @dev withdraws a users bridge liquidity for WETH
     * @param amount the amount to be redeemed
     */
    function removeLiquidityWeth(uint256 amount) external;
}
