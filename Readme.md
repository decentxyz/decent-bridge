# Decent Bridge

This project hosts the contracts that power the Decent bridge. It's built
using LayerZero's OFT contracts.

## Setup

1. Install [Foundry](https://book.getfoundry.sh/getting-started/installation#using-foundryup).
2. Install packages:

```
forge install
```

3. Make sure you have money on both Sepolia and FTM. Here are two generous
   faucets for this:

   1. [Alchemy's Sepolia Faucet](https://sepoliafaucet.com/)
   2. [Fantom's testnet faucet](https://faucet.fantom.network/)

4. (On Mac OS) Sometimes, MacOS by default has some wack version of
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

# Deploying Contracts

To deploy contracts, you need to have a `.env` file in the root of this
project. Refer to `.env.example` for reference.

Then, you can deploy contracts with:

```bash
make bridge-e2e
```

Refer to the Makefile for more commands, or to see what `bridge-e2e`
does.

## How does deployment work?

### Deploying the Router

First we have to deploy the router contracts. The script for this deployment
is in [DeployRouter.s.sol](./script/DeployRouter.s.sol).

### Wiring up Contracts

The router contract on one chain needs to know about the other contracts
on the target chains. So, we have to wire them up and let them know of
each other. The [WireUpContracts.s.sol](./script/WireUpContracts.s.sol)
does exactly just that.

### Bridging Tokens

To bridge tokens, use the [BridgeEth.s.sol](./script/BridgeEth.s.sol) contract.
