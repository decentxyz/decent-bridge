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
import { aliasLookup } from "../constants";

const chains = [
  ChainId.ETHEREUM,
  ChainId.ARBITRUM,
  ChainId.OPTIMISM,
  ChainId.ZORA,
  ChainId.BASE,
];

export const getDeployerAddress = (): Address => {
  return ensureEnv("TESTNET_ACCOUNT_ADDRESS") as Address;
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

    const testClient = await hre.viem.getTestClient({
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

    await testClient.setBalance({
      address: getDeployerAddress(),
      value: parseEther("1000"),
    });
  };

  await Promise.all(chains.map(_start));
  await sleep(1000);
  await hre.run("start-glue");
});

const getScript = (name: string) => `script/Scripts.s.sol:${name}`;

const beep = "*".repeat(30);
enum Runtime {
  MAINNET = "mainnet",
  TESTNET = "testnet",
  FORKNET = "forknet",
}
const ensureEnv = (key: string): string => {
  const value = process.env[key];
  if (value === undefined) {
    throw new Error(`env var ${key} not set`);
  }
  return value;
};

const commonParams: Record<Runtime, string> = {
  [Runtime.MAINNET]: `--broadcast -vvvv --private-key=${beep} --verify --slow`,
  [Runtime.TESTNET]: `--broadcast -vvvv --private-key=${beep} --verify --slow`,
  [Runtime.FORKNET]: `--broadcast -vvvv --unlocked --sender=${ensureEnv(
    "TESTNET_ACCOUNT_ADDRESS",
  )}`,
};

const uncensor = (cmd: string, runtime: Runtime) => {
  if (runtime === Runtime.MAINNET) {
    return cmd.replace(beep, ensureEnv("MAINNET_ACCOUNT"));
  } else if (runtime === Runtime.TESTNET) {
    return cmd.replace(beep, ensureEnv("TESTNET_ACCOUNT"));
  }
  return cmd;
};

const buildCmd = (
  envs: Lookup<string, string>,
  scriptName: string,
  runtime: Runtime,
) => {
  const envStr = Object.keys(envs)
    .map((key) => `${key}=${envs[key]}`)
    .join(" ");
  return `${envStr} forge script ${getScript(scriptName)} ${
    commonParams[runtime]
  }`;
};

type TaskType = ReturnType<typeof task>;

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
    "comma-separated list of chains to do the setup with",
    chains.map((chain) => aliasLookup[chain]).join(","),
  );

export const srcDstParam = (targetTask: TaskType): TaskType =>
  targetTask
    .addParam<string>("src", "src chain")
    .addParam<string>("dst", "dst chain");

export const addParams = (adders: ((t: TaskType) => TaskType)[], t: TaskType) =>
  adders.forEach((adder) => adder(t));

addParams(
  [chainParam, runtimeParam],
  task<{
    runtime: Runtime;
    chain: string;
  }>("deploy", async ({ runtime, chain }, hre) => {
    let cmd = buildCmd({ chain }, "Deploy", runtime);
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
    let cmd = buildCmd({ src, dst }, "WireUp", runtime);
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
    let cmd = buildCmd(
      { chain, liquidity: formatUnits(parseEther(amount), 0) },
      "AddLiquidity",
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
  [runtimeParam, srcDstParam, amountParam],
  task<{
    runtime: Runtime;
    src: string;
    dst: string;
    amount: string;
  }>("bridge", async ({ runtime, src, dst, amount }, hre) => {
    let cmd = buildCmd(
      { src, dst, bridge_amount: formatUnits(parseEther(amount), 0) },
      "Bridge",
      runtime,
    );
    console.log(`running cmd: "${cmd}"`);
    cmd = uncensor(cmd, runtime);
    exec(cmd);
  }),
);
