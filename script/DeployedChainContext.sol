// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {CommonBase} from "forge-std/Base.sol";
import {DecentEthRouter} from "src/DecentEthRouter.sol";
import {DcntEth} from "src/DcntEth.sol";
import {DeploymentHelpers} from "./DeploymentHelpers.sol";

contract DeployedChainContext is DeploymentHelpers {
    // to be read from env vars
    string chainAlias;
    string chainId;
    // to be grabbed from the last run
    DecentEthRouter router;
    DcntEth dcntEth;

    function setUp() public {
        router = DecentEthRouter(
            payable(
                getFromLastRun(
                    chainId,
                    '$.transactions[?(@.contractName == "DecentEthRouter")].contractAddress'
                )
            )
        );
        dcntEth = DcntEth(
            payable(
                getFromLastRun(
                    chainId,
                    '$.transactions[?(@.contractName == "DcntEth")].contractAddress'
                )
            )
        );
    }
}
