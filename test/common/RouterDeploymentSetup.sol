// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Executor} from "../../src/Executor.sol";
import {OpenDcntEth} from "./OpenDcntEth.sol";
import {DecentEthRouter} from "../../src/DecentEthRouter.sol";
import {DcntEth} from "../../src/DcntEth.sol";
import {LzChainSetup} from "./LzChainSetup.sol";
import {DeploymentRecorder} from "./DeploymentRecorder.sol";
import {console2} from "forge-std/console2.sol";

contract RouterDeploymentSetup is LzChainSetup, DeploymentRecorder {
    mapping(string => DecentEthRouter) routerLookup;
    mapping(string => DcntEth) dcntEthLookup;
    uint MIN_DST_GAS = 100000;

    function deployRouterAndDecentEth(string memory chain) public {
        string memory chainRecordKey = startRecording(chain);
        switchTo(chain);
        Executor executor = new Executor(
            payable(wethLookup[chain]),
            gasEthLookup[chain]
        );
        DecentEthRouter router = new DecentEthRouter(
            payable(wethLookup[chain]),
            gasEthLookup[chain],
            address(executor)
        );
        executor.transferOwnership(address(router));
        vm.serializeAddress(chainRecordKey, "router", address(router));

        routerLookup[chain] = router;
        DcntEth dcntEth;
        address lzEndpoint = address(lzEndpointLookup[chain]);
        if (isForgeTest()) {
            dcntEth = new OpenDcntEth(lzEndpoint);
        } else {
            dcntEth = new DcntEth(lzEndpoint);
        }
        dcntEthLookup[chain] = dcntEth;
        vm.serializeAddress(chainRecordKey, "decentEth", address(dcntEth));
        dumpChainDeployments(chain);
    }

    function registerDecentEth(string memory chain) public {
        DcntEth dcntEth = dcntEthLookup[chain];
        DecentEthRouter router = routerLookup[chain];
        console2.log("dcntEth & router: ", address(dcntEth), address(router));
        router.registerDcntEth(address(dcntEth));
        dcntEth.transferOwnership(address(router));
    }

    function deployAndRegister(string memory chain) public {
        deployRouterAndDecentEth(chain);
        registerDecentEth(chain);
    }

    function _wireUpRouterOneDirection(
        string memory src,
        string memory dst
    ) private {
        switchTo(src);
        DecentEthRouter srcRouter = routerLookup[src];
        startImpersonating(srcRouter.owner());
        srcRouter.addDestinationBridge(
            lzIdLookup[dst],
            address(routerLookup[dst]),
            address(dcntEthLookup[dst]),
            MIN_DST_GAS
        );
        stopImpersonating();
    }

    function wireUp(string memory src, string memory dst) public {
        _wireUpRouterOneDirection(src, dst);
        _wireUpRouterOneDirection(dst, src);
    }
}
