// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Executor} from "../../src/Executor.sol";
import {OpenDcntEth} from "./OpenDcntEth.sol";
import {DecentEthRouter} from "../../src/DecentEthRouter.sol";
import {DcntEth} from "../../src/DcntEth.sol";
import {console2} from "forge-std/console2.sol";
import {LzChainSetup} from "arshans-forge-toolkit/LzChainSetup.sol";
import {ChainDeployer} from "better-deployer/ChainDeployer.sol";

contract RouterDeploymentSetup is LzChainSetup, ChainDeployer {
    mapping(string => DecentEthRouter) routerLookup;
    mapping(string => DcntEth) dcntEthLookup;
    uint MIN_DST_GAS = 100000;

    function deployRouterAndDecentEth(string memory chain) public {
        switchTo(chain);

        Executor executor = Executor(
            payable(
                deployChain(
                    chain,
                    "executor",
                    "Executor.sol:Executor",
                    abi.encode(payable(wethLookup[chain]), gasEthLookup[chain])
                )
            )
        );

        DecentEthRouter router = DecentEthRouter(
            payable(
                deployChain(
                    chain,
                    "router",
                    "DecentEthRouter.sol:DecentEthRouter",
                    abi.encode(
                        payable(wethLookup[chain]),
                        gasEthLookup[chain],
                        address(executor)
                    )
                )
            )
        );

        executor.transferOwnership(address(router));

        routerLookup[chain] = router;
        DcntEth dcntEth;
        address lzEndpoint = address(lzEndpointLookup[chain]);
        if (isForgeTest()) {
            dcntEth = OpenDcntEth(
                deployChain(
                    chain,
                    "dcntEth",
                    "OpenDcntEth.sol:OpenDcntEth",
                    abi.encode(lzEndpoint)
                )
            );
        } else {
            dcntEth = DcntEth(
                deployChain(
                    chain,
                    "dcntEth",
                    "DcntEth.sol:DcntEth",
                    abi.encode(lzEndpoint)
                )
            );
        }
        dcntEthLookup[chain] = dcntEth;
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
        if (!isForgeTest()) {
            dump();
        }
    }

    function wireUpSrcToDst(string memory src, string memory dst) public {
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
        wireUpSrcToDst(src, dst);
        wireUpSrcToDst(dst, src);
    }
}
