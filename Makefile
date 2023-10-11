include .env

deploy-ftm:
	ETHERSCAN_API_KEY=$(FTMSCAN_API_KEY) \
	forge script script/Counter.s.sol:CounterScript \
		--rpc-url $(FTM_TESTNET_RPC) --broadcast --verify -vvvv

##### whole lotta convenience scripts
watch-test:
	forge test -vv --watch --match-path test/Counter.t.sol

install-solmate:
	forge install transmissions11/solmate

install-openzeppelin:
	forge install https://github.com/OpenZeppelin/openzeppelin-contracts
    forge install https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable

setup-prettier:
	pnpm init
	pnpm add --save-dev prettier prettier-plugin-solidity
