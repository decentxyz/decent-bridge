import { task } from "hardhat/config";
import "@nomicfoundation/hardhat-viem";
import "@decent.xyz/houndry-toolkit";
import {
  ChainId,
  getforkPort,
  getForkRpc,
  getWagmiChain,
  Lookup,
  sleep,
} from "@decent.xyz/box-common";
import { exec } from "shelljs";
import { Address, defineChain, formatUnits, http, parseEther } from "viem";
import { aliasLookup, chainIdFromAlias } from "../constants";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const chains = [
  ChainId.ETHEREUM,
  ChainId.ARBITRUM,
  ChainId.OPTIMISM,
  ChainId.ZORA,
  ChainId.BASE,
  ChainId.POLYGON,
];

export const getDeployerAddress = (): Address => {
  return ensureEnv("TESTNET_ACCOUNT_ADDRESS") as Address;
};

export const getForknetTestClient = async ({
  chainId,
  chain,
  hre,
}: {
  chainId?: ChainId;
  chain?: string;
  hre: HardhatRuntimeEnvironment;
}) => {
  if (chainId == undefined && chain == undefined) {
    throw Error(`at least one of chain alias or chain id must be provided`);
  }
  chainId = chainId !== undefined ? chainId : chainIdFromAlias[chain!];
  return hre.viem.getTestClient({
    chain: defineChain({
      ...getWagmiChain(chainId),
      rpcUrls: {
        default: { http: [getForkRpc(chainId)] },
        public: { http: [getForkRpc(chainId)] },
      },
    }),
    mode: "anvil",
    transport: http(),
  });
};

task("start-forknets", async (action, hre) => {
  const _start = async (chainId: ChainId) => {
    const chain = aliasLookup[chainId];
    const port = `${getforkPort(chainId)}`;

    await hre.run("start-fork", {
      chain,
      port,
      additionalArgs: `--auto-impersonate`,
    });

    await sleep(1000);

    const testClient = await getForknetTestClient({ hre, chain });

    await testClient.setBalance({
      address: getDeployerAddress(),
      value: parseEther("1000"),
    });
  };

  for (const chainId of chains) {
    await _start(chainId);
    await sleep(100);
  }

  await sleep(1000);
  await hre.run("start-glue");
});

const getScriptPath = (name: string) => `script/Scripts.s.sol:${name}`;

export const beep = "*".repeat(30);
export enum Runtime {
  MAINNET = "mainnet",
  TESTNET = "testnet",
  FORKNET = "forknet",
}
export const ensureEnv = (key: string): string => {
  const value = process.env[key];
  if (value === undefined) {
    throw new Error(`env var ${key} not set`);
  }
  return value;
};

export const commonParams: Record<Runtime, string> = {
  [Runtime.MAINNET]: `--broadcast -vvvv --private-key=${beep} --verify --slow`,
  [Runtime.TESTNET]: `--broadcast -vvvv --private-key=${beep} --verify --slow`,
  [Runtime.FORKNET]: `--broadcast -vvvv --unlocked --sender=${ensureEnv(
    "TESTNET_ACCOUNT_ADDRESS",
  )}`,
};

export const uncensor = (cmd: string, runtime: Runtime) => {
  if (runtime === Runtime.MAINNET) {
    return cmd.replace(beep, ensureEnv("MAINNET_ACCOUNT"));
  } else if (runtime === Runtime.TESTNET) {
    return cmd.replace(beep, ensureEnv("TESTNET_ACCOUNT"));
  }
  return cmd;
};

export const buildScriptCmd = (
  envs: Lookup<string, string>,
  scriptPath: string,
  runtime: Runtime,
) => {
  const envStr = Object.keys(envs)
    .map((key) => `${key}=${envs[key]}`)
    .join(" ");
  return `${envStr} forge script ${scriptPath} ${commonParams[runtime]}`;
};

export type TaskType = ReturnType<typeof task>;

export const chainParam = (targetTask: TaskType): TaskType =>
  targetTask.addParam<string>("chain", "chain to deploy to");

export const amountParam = (targetTask: TaskType): TaskType =>
  targetTask.addParam<string>("amount", "amount (in eth)");
export const runtimeParam = (targetTask: TaskType): TaskType =>
  targetTask.addOptionalParam<Runtime>(
    "runtime",
    "runtime of deployment: mainnet, testnet, or forknet",
    Runtime.FORKNET,
  );

export const chainsParam = (targetTask: TaskType): TaskType =>
  targetTask.addOptionalParam<string>(
    "chains",
    "comma-separated list of chains",
    chains.map((chain) => aliasLookup[chain]).join(","),
  );

export const srcDstParam = (targetTask: TaskType): TaskType =>
  targetTask
    .addParam<string>("src", "src chain")
    .addParam<string>("dst", "dst chain");

export const fromToParam = (targetTask: TaskType): TaskType =>
  targetTask
    .addOptionalParam<string>("from", "from address")
    .addOptionalParam<string>("to", "to address");

export type ParamAdder = (t: TaskType) => TaskType;
export const addParams = (adders: ParamAdder[], t: TaskType) =>
  adders.forEach((adder) => adder(t));

addParams(
  [chainParam, runtimeParam],
  task<{
    runtime: Runtime;
    chain: string;
  }>("deploy-decent-bridge", async ({ runtime, chain }, hre) => {
    let cmd = buildScriptCmd({ chain }, getScriptPath("Deploy"), runtime);
    console.log(`running cmd: "${cmd}"`);
    cmd = uncensor(cmd, runtime);
    exec(cmd);
  }),
);

addParams(
  [runtimeParam, srcDstParam],
  task<{
    runtime: Runtime;
    src: string;
    dst: string;
  }>("wire-up-src-to-dst", async ({ runtime, src, dst }, hre) => {
    let cmd = buildScriptCmd({ src, dst }, getScriptPath("WireUp"), runtime);
    console.log(`running cmd: "${cmd}"`);
    cmd = uncensor(cmd, runtime);
    console.log(`wiring up ${src} to ${dst}`);
    exec(cmd);
  }),
);

addParams(
  [runtimeParam, srcDstParam],
  task<{
    runtime: Runtime;
    src: string;
    dst: string;
  }>("wire-up", async ({ runtime, src: _src, dst: _dst }, hre) => {
    await Promise.all([
      hre.run("wire-up-src-to-dst", { runtime, src: _src, dst: _dst }),
      hre.run("wire-up-src-to-dst", { runtime, src: _dst, dst: _src }),
    ]);
  }),
);

addParams(
  [runtimeParam, chainParam, amountParam],
  task<{
    chain: string;
    runtime: Runtime;
    amount: string;
  }>("add-liquidity", async ({ runtime, amount, chain }, hre) => {
    let cmd = buildScriptCmd(
      { chain, liquidity: formatUnits(parseEther(amount), 0) },
      getScriptPath("AddLiquidity"),
      runtime,
    );
    console.log(`running cmd: "${cmd}"`);
    cmd = uncensor(cmd, runtime);
    exec(cmd);
  }),
);

addParams(
  [runtimeParam, chainsParam],
  task<{
    chains: string;
    runtime: Runtime;
    amount: string;
  }>("full-setup", async ({ runtime, chains: _chains, amount }, hre) => {
    const chains = _chains.split(",");
    const _deployAndAddLiquidity = async () => {
      await Promise.all(
        chains.map(async (chain) => {
          await hre.run("deploy", { runtime, chain });
          await hre.run("add-liquidity", { runtime, chain, amount });
        }),
      );
    };

    const _wireUp = async () =>
      Promise.all(
        chains.flatMap((src) =>
          chains
            .filter((dst) => dst !== src)
            .map(async (dst) => {
              await hre.run("wire-up-src-to-dst", { runtime, src, dst });
            }),
        ),
      );

    await _deployAndAddLiquidity();
    await _wireUp();
  }).addOptionalParam<string>(
    "amount",
    "amount of liquidity (in eth) to add to those chains",
    "100",
  ),
);

addParams(
  [chainParam],
  task<{
    chain: string;
  }>("watch-logs", async ({ chain }, hre) => {
    exec(`tail -f .forks/${chain}.log`);
  }),
);

addParams(
  [runtimeParam, srcDstParam, amountParam, fromToParam],
  task<{
    runtime: Runtime;
    src: string;
    dst: string;
    amount: string;
    from: string;
    to: string;
  }>("bridge", async ({ runtime, src, dst, amount, from, to }, hre) => {
    let cmd = buildScriptCmd(
      { src, dst, bridge_amount: formatUnits(parseEther(amount), 0), from, to },
      getScriptPath("Bridge"),
      runtime,
    );
    console.log(`running cmd: "${cmd}"`);
    cmd = uncensor(cmd, runtime);
    exec(cmd);
  }),
);
