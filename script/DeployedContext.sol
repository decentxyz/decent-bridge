// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {CommonBase} from "forge-std/Base.sol";
import {DecentEthRouter} from "src/DecentEthRouter.sol";
import {DcntEth} from "src/DcntEth.sol";
import {DeploymentHelpers} from "./DeploymentHelpers.sol";

contract DeployedContext is DeploymentHelpers {
    string srcChainAlias;
    string srcChainId;
    string dstChainId;
    uint MIN_DST_GAS = 100000;
    DecentEthRouter srcRouter;
    DecentEthRouter dstRouter;
    DcntEth dstDcntEth;
    uint16 dstLzId;

    function setUp() public {
        srcRouter = DecentEthRouter(
            payable(
                getFromLastRun(srcChainId, ".transactions[0].contractAddress")
            )
        );
        dstRouter = DecentEthRouter(
            payable(
                getFromLastRun(dstChainId, ".transactions[0].contractAddress")
            )
        );
        dstDcntEth = DcntEth(
            payable(
                getFromLastRun(
                    dstChainId,
                    ".transactions[1].additionalContracts[0].address"
                )
            )
        );
    }
}
