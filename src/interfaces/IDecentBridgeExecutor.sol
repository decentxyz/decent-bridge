pragma solidity ^0.8.0;

import {IOFTV2} from "solidity-examples/token/oft/v2/interfaces/IOFTV2.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

interface IDecentBridgeExecutor {

    /**
     * @dev called upon receiving dcntEth in the DecentEthRouter
     * @param from the senders address for refund
     * @param target target contract
     * @param deliverEth delivers WETH if false
     * @param amount amount of the transaction
     * @param callPayload payload for the tx
     */
    function execute(
      address from,
      address target,
      bool deliverEth,
      uint256 amount,
      bytes memory callPayload
    ) external;
}
