// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LzChainSetup} from "./LzChainSetup.sol";

contract AllChainsInfo is LzChainSetup {
    address OP_STACK_WETH = 0x4200000000000000000000000000000000000006;

    function configureOptimism() private {
        configureChain("optimism", true, 10, OP_STACK_WETH);
        chainIsSet["optimism"] = true;
        configureLzChain(
            "optimism",
            111,
            0x3c2269811836af69497E5F486A85D7316753cf62
        );
    }

    function configureBase() private {
        configureChain("base", true, 8453, OP_STACK_WETH);
        configureLzChain(
            "base",
            184,
            0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7
        );
        chainIsSet["base"] = true;
    }

    function configureArbitrum() private {
        chainIsSet["arbitrum"] = true;
        configureChain(
            "arbitrum",
            true,
            42161,
            0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
        );
        configureLzChain(
            "arbitrum",
            110,
            address(0x3c2269811836af69497E5F486A85D7316753cf62)
        );
    }

    function configureEthereum() private {
        chainIsSet["ethereum"] = true;
        configureChain(
            "ethereum",
            true,
            1,
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        );
        configureLzChain(
            "ethereum",
            101,
            0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675
        );
    }

    function configureSepolia() private {
        chainIsSet["sepolia"] = true;
        configureChain(
            "sepolia",
            true,
            11155111,
            0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9
        );
        configureLzChain(
            "sepolia",
            10161,
            0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1
        );
    }

    function configureFtmTestnet() private {
        chainIsSet["ftm-testnet"] = true;
        configureChain(
            "ftm-testnet",
            false,
            4002,
            0x07B9c47452C41e8E00f98aC4c075F5c443281d2A
        );
        configureLzChain(
            "ftm-testnet",
            10112,
            0x7dcAD72640F835B0FA36EFD3D6d3ec902C7E5acf
        );
    }

    function configureZora() private {
        chainIsSet["zora"] = true;
        configureChain("zora", true, 7777777, OP_STACK_WETH);
        configureLzChain(
            "zora",
            195,
            0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7
        );
    }

    function configureZoraGoerli() private {
        chainIsSet["zora-goerli"] = true;
        configureChain("zora-goerli", true, 999, OP_STACK_WETH);
        configureLzChain(
            "zora-goerli",
            10195,
            0x83c73Da98cf733B03315aFa8758834b36a195b87
        );
    }

    function configureOptimismGoerli() private {
        chainIsSet["optimism-goerli"] = true;
        configureChain("optimism-goerli", true, 420, OP_STACK_WETH);
        configureLzChain(
            "optimism-goerli",
            10132,
            0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1
        );
    }

    function configureAvalanche() private {
        chainIsSet["avalanche"] = true;
        configureChain(
            "avalanche",
            false,
            43114,
            0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB
        );
        configureLzChain(
            "avalanche",
            106,
            0x3c2269811836af69497E5F486A85D7316753cf62
        );
    }

    function configurePolygon() private {
        chainIsSet["polygon"] = true;
        configureChain(
            "polygon",
            false,
            137,
            0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619
        );
        configureLzChain(
            "polygon",
            109,
            0x3c2269811836af69497E5F486A85D7316753cf62
        );
    }

    function setupChainInfo() public {
        configureSepolia();
        configureOptimismGoerli();
        configureZoraGoerli();
        configureFtmTestnet();

        configureEthereum();
        configureArbitrum();
        configureOptimism();
        configureBase();
        configureZora();
        configureAvalanche();
        configurePolygon();
    }
}
