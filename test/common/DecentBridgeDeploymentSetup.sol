// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {DecentBridgeExecutor} from "../../src/DecentBridgeExecutor.sol";
import {DecentEthRouter} from "../../src/DecentEthRouter.sol";
import {DcntEth} from "../../src/DcntEth.sol";
import {console2} from "forge-std/console2.sol";
import {ChainDeployer} from "better-deployer/ChainDeployer.sol";
import {LoadAllChainInfo} from "forge-toolkit/LoadAllChainInfo.sol";

contract DecentBridgeDeploymentSetup is LoadAllChainInfo, ChainDeployer {
    mapping(string => DecentEthRouter) routerLookup;
    mapping(string => DcntEth) dcntEthLookup;
    mapping(string => DecentBridgeExecutor) decentBridgeExecutorLookup;
    uint MIN_DST_GAS = 100000;

    function deployDecentBridgeRouterAndDecentEth(string memory chain) public {
        switchTo(chain);

        DecentBridgeExecutor executor = DecentBridgeExecutor(
            payable(
                deployChain(
                    chain,
                    "DecentBridgeExecutor",
                    "DecentBridgeExecutor.sol:DecentBridgeExecutor",
                    abi.encode(payable(wethLookup[chain]), gasEthLookup[chain])
                )
            )
        );

        DecentEthRouter router = DecentEthRouter(
            payable(
                deployChain(
                    chain,
                    "DecentEthRouter",
                    "DecentEthRouter.sol:DecentEthRouter",
                    abi.encode(
                        payable(wethLookup[chain]),
                        gasEthLookup[chain],
                        address(executor)
                    )
                )
            )
        );

        executor.setOperator(address(router));

        decentBridgeExecutorLookup[chain] = executor;
        routerLookup[chain] = router;
        DcntEth dcntEth;
        address lzEndpoint = address(lzEndpointLookup[chain]);
        dcntEth = DcntEth(
            deployChain(
                chain,
                "DcntEth",
                "DcntEth.sol:DcntEth",
                abi.encode(lzEndpoint)
            )
        );
        dcntEthLookup[chain] = dcntEth;
    }

    function registerDecentEth(string memory chain) public {
        DcntEth dcntEth = dcntEthLookup[chain];
        DecentEthRouter router = routerLookup[chain];
        console2.log("dcntEth & router: ", address(dcntEth), address(router));
        router.registerDcntEth(address(dcntEth));
        dcntEth.setRouter(address(router));
    }

    function deployDecentBridgeRouterAndRegisterDecentEth(
        string memory chain
    ) public {
        deployDecentBridgeRouterAndDecentEth(chain);
        registerDecentEth(chain);
        if (!isForgeTest()) {
            dump();
        }
    }

    function wireUpSrcToDstDecentBridge(
        string memory src,
        string memory dst
    ) public {
        switchTo(src);
        DecentEthRouter srcRouter = routerLookup[src];
        DcntEth srcDcntEth = dcntEthLookup[src];
        DcntEth dstDcntEth = dcntEthLookup[dst];
        srcRouter.addDestinationBridge(
            lzIdLookup[dst],
            address(routerLookup[dst])
        );
        srcDcntEth.setTrustedRemote(
            lzIdLookup[dst],
            abi.encodePacked(dstDcntEth, srcDcntEth)
        );
        srcDcntEth.setMinDstGas(
            lzIdLookup[dst],
            srcDcntEth.PT_SEND_AND_CALL(),
            MIN_DST_GAS
        );
    }

    function wireUp(string memory src, string memory dst) public {
        wireUpSrcToDstDecentBridge(src, dst);
        wireUpSrcToDstDecentBridge(dst, src);
    }
}
