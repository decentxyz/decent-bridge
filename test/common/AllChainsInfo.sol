// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LzChainSetup} from "./LzChainSetup.sol";

contract AllChainsInfo is LzChainSetup {
    address OP_STACK_WETH = 0x4200000000000000000000000000000000000006;

    function configureOptimism() private {
        configureChain("optimism", true, 10, OP_STACK_WETH);
        configureLzChain(
            "optimism",
            111,
            address(0x3c2269811836af69497E5F486A85D7316753cf62)
        );
    }

    function configureArbitrum() private {
        configureChain(
            "arbitrum",
            true,
            42161,
            address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1)
        );
        configureLzChain(
            "arbitrum",
            110,
            address(0x3c2269811836af69497E5F486A85D7316753cf62)
        );
    }

    function configureEthereum() private {
        configureChain(
            "ethereum",
            true,
            1,
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
        );
        configureLzChain(
            "ethereum",
            101,
            address(0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675)
        );
    }

    function configureZora() private {
        configureChain("zora", true, 7777777, OP_STACK_WETH);
        configureLzChain(
            "zora",
            195,
            address(0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7)
        );
    }

    function configureAvalanche() private {
        configureChain(
            "avalanche",
            false,
            43114,
            0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB
        );
        configureLzChain(
            "avalanche",
            106,
            address(0x3c2269811836af69497E5F486A85D7316753cf62)
        );
    }

    function configurePolygon() private {
        configureChain(
            "polygon",
            false,
            137,
            0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619
        );
        configureLzChain(
            "polygon",
            109,
            address(0x3c2269811836af69497E5F486A85D7316753cf62)
        );
    }

    function setupChainInfo() public {
        configureEthereum();
        configureArbitrum();
        configureOptimism();
        configureZora();
        configureAvalanche();
        configurePolygon();
    }
}
