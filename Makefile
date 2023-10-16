include .env

COMMON_PARAMS := --private-key=$(TESTNET_ACCOUNT) --slow --broadcast --verify -vvvv

bridge-e2e: deploy-router-all wire-up-all bridge-ftm-to-sepolia
	echo "done!"

bridge-ftm-to-sepolia:
	SCRIPT_NAME=BridgeFtmToSepolia make bridge

bridge:
	forge script script/BridgeEth.s.sol:$(SCRIPT_NAME) $(COMMON_PARAMS)

WIREUP_CONFIGS := WireUpSepoliaToFtm WireUpFtmToSepolia

wire-up-all:
	for script_name in $(WIREUP_CONFIGS); do \
		make wire-up SCRIPT_NAME=$$script_name; \
	done

wire-up:
	forge script script/WireUpContracts.s.sol:$(SCRIPT_NAME) $(COMMON_PARAMS)

ROUTERS := DeployFtm DeploySepolia
deploy-router-all:
	for script_name in $(ROUTERS); do \
		make deploy-router SCRIPT_NAME=$$script_name; \
	done

deploy-router:
	forge script script/DeployRouter.s.sol:$(SCRIPT_NAME) $(COMMON_PARAMS)

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
