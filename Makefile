include .env

deploy:
	forge script script/DecentEthRouter.s.sol:DeployRouter \
		--private-key=$(TESTNET_ACCOUNT) \
		--broadcast --verify -vvv


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
