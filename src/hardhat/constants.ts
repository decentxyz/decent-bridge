import { ChainId } from "@decent.xyz/box-common";

export const aliasLookup: Record<ChainId, string> = {
  [ChainId.ETHEREUM]: "ethereum",
  [ChainId.SEPOLIA]: "sepolia",
  [ChainId.GOERLI]: "goerli",
  [ChainId.OPTIMISM]: "optimism",
  [ChainId.OPTIMISM_TESTNET]: "optimism-testnet",
  [ChainId.POLYGON]: "polygon",
  [ChainId.POLYGON_TESTNET]: "polygon-testnet",
  [ChainId.ARBITRUM]: "arbitrum",
  [ChainId.ARBITRUM_TESTNET]: "arbitrum-testnet",
  [ChainId.BASE]: "base",
  [ChainId.ZORA]: "zora",
  [ChainId.ZORA_GOERLI]: "zora-goerli",
  [ChainId.BASE_TESTNET]: "base-testnet",
  [ChainId.MOONBEAM]: "moonbeam",
  [ChainId.MOONBEAM_TESTNET]: "moonbeam-testnet",
  [ChainId.AVALANCHE]: "avalanche",
  [ChainId.AVALANCHE_TESTNET]: "avalanche-testnet",
  [ChainId.FANTOM]: "fantom",
  [ChainId.FANTOM_TESTNET]: "fantom-testnet",
  [ChainId.SOLANA_DEVNET]: "solana-devnet",
  [ChainId.SOLANA_MAINNET]: "solana",
};

const chainIdFromAlias: { [key: string]: ChainId } = Object.keys(
  aliasLookup,
).reduce(
  (acc, key) => {
    const value = aliasLookup[parseInt(key) as ChainId];
    // @ts-ignore
    acc[value] = key;
    return acc;
  },
  {} as { [key: string]: ChainId },
);

export { chainIdFromAlias };
