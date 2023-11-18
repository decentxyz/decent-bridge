// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {OpenDcntEth} from "./OpenDcntEth.sol";
import {DecentEthRouter} from "../../src/DecentEthRouter.sol";
import {DcntEth} from "../../src/DcntEth.sol";
import {LzChainSetup} from "./LzChainSetup.sol";

contract RouterDeploymentSetup is LzChainSetup {
    mapping(string => DecentEthRouter) routerLookup;
    mapping(string => DcntEth) dcntEthLookup;
    uint MIN_DST_GAS = 100000;

    function deployRouter(string memory chain) public {
        switchTo(chain);
        DecentEthRouter router = new DecentEthRouter(
            payable(wethLookup[chain]),
            gasEthLookup[chain]
        );
        routerLookup[chain] = router;
        DcntEth dcntEth;
        address lzEndpoint = address(lzEndpointLookup[chain]);
        if (isTestRuntime) {
            dcntEth = new OpenDcntEth(lzEndpoint);
        } else {
            dcntEth = new DcntEth(lzEndpoint);
        }
        dcntEth.transferOwnership(address(router));
        router.registerDcntEth(address(dcntEth));
        dcntEthLookup[chain] = dcntEth;
    }

    function _wireUpRouterOneDirection(
        string memory src,
        string memory dst
    ) private {
        switchTo(src);
        DecentEthRouter srcRouter = routerLookup[src];
        srcRouter.addDestinationBridge(
            lzIdLookup[dst],
            address(routerLookup[dst]),
            address(dcntEthLookup[dst]),
            MIN_DST_GAS
        );
    }

    function wireUp(string memory src, string memory dst) public {
        _wireUpRouterOneDirection(src, dst);
        _wireUpRouterOneDirection(dst, src);
    }
}
