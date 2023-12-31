# Decent Bridge

This project hosts the contracts that power the Decent bridge. It's built
using LayerZero's OFT contracts.

## Setup

1. Install [Foundry](https://book.getfoundry.sh/getting-started/installation#using-foundryup).
2. Install packages:

```
forge install
```

3. Install node packages:

```
pnpm i
```

## Tests

```bash
forge test
```

## Hardhat Tasks

Just like [houndry-toolkit](https://github.com/decentxyz/houndry-toolkit), this project
uses tons of hardhat tasks. In fact it [uses houndry-toolkit](./package.json#L25) as a
dependency, so it inherits all the HH (Hardhat) tasks that `houndry-toolkit` exports.

Run

```
npx hardhat --help
```

and you'll see:

```bash
AVAILABLE TASKS:

  add-liquidity
  bridge
  check               	Check whatever you need
  clean               	Clears the cache and deletes all artifacts
  compile             	Compiles the entire project, building all artifacts
  console             	Opens a hardhat console
  deploy-decent-bridge
  flatten             	Flattens and prints contracts and their dependencies. If no file is passed, all the contracts in the project will be flattened.
  full-setup
  help                	Prints this message
  list-forks          	lists all running forks
  node                	Starts a JSON-RPC server on top of Hardhat Network
  run                 	Runs a user-defined script after compiling the project
  start-fork          	starts a fork of a chain
  start-forknets
  start-forks         	starts forks of multiple chains
  start-glue          	starts the glue service
  stop-all-forks      	lists all running forks
  stop-fork
  stop-glue           	starts the glue service
  test                	Runs mocha tests
  watch-logs
  wire-up
  wire-up-src-to-dst
```

The new tasks are as follows:

### `start-forknets`

A utility task for running a whole bunch of forknets at the
[standardized ports](https://github.com/decentxyz/box-monorepo/blob/main/packages/box-common/src/constants/Web3Constants.ts#L93)
that we have defined in `box-common.`

These are the [chains](./src/hardhat/tasks/decentBridgeTasks.ts#L17) that it starts.

### `deploy-decent-bridge`

Deploys the decent bridge.

```
pnpm task deploy-decent-bridge --chain polygon --runtime forknet
```

### `wire-up`

Wires up the contracts from a source chain to a dst chain:

```
pnpm task wire-up --src arbitrum --dst optimism
```

### `add-liquidity`

```
pnpm task wire-up --chain arbitrum --amount 1.2 --runtime mainnet
```

## Testnet Faucets

When developing, previously we deployed these contracts to Sepolia and FTM.
Here are two generous faucets for this:

1.  [Alchemy's Sepolia Faucet](https://sepoliafaucet.com/)
2.  [Fantom's testnet faucet](https://faucet.fantom.network/)

## (Optional) running make scripts

(On Mac OS) Sometimes, MacOS by default has some wack version of
`make` installed. You can easily install the correct version with:

```bash
brew install make # binary's called gmake
```

Then you have to alias it in your rc file. Add this line to the bottom of
your rcfile: That's `~/.zshrc` if you're using zsh, and it's `~/.bashrc` if
you're using bash. You can check which shell you're using with `echo $SHELL`.

```bash
alias make="gmake"
```
