include .env

COMMON_PARAMS := --slow --broadcast --verify -vvvv

ifeq ($(MAINNET),true)
    COMMON_PARAMS += --private-key=$(MAINNET_ACCOUNT)
else
    COMMON_PARAMS += --private-key=$(TESTNET_ACCOUNT)
endif

DECIMALS := 1000000000000000000 # for convenience

add-liquidity:
	$(eval LIQUIDITY=$(shell echo "scale=10; $(AMOUNT) * $(DECIMALS)" | bc | sed 's/\..*//'))
	LIQUIDITY=$(LIQUIDITY) \
	CHAIN_ID=$$(jq -r '.["$(CHAIN)"].chainId' deployConfig.json) \
	MAINNET=$$(jq -r '.["$(CHAIN)"].isMainnet' deployConfig.json) \
	forge script script/AddLiquidity.s.sol:AddLiquidity $(COMMON_PARAMS)

deploy:
	CHAIN_ID=$$(jq -r '.["$(CHAIN)"].chainId' deployConfig.json) \
	LZ_ENDPOINT=$$(jq -r '.["$(CHAIN)"].lzEndpoint' deployConfig.json) \
	GAS_ETH=$$(jq -r '.["$(CHAIN)"].isGasEth' deployConfig.json) \
	WETH=$$(jq -r '.["$(CHAIN)"].weth' deployConfig.json) \
	MAINNET=$$(jq -r '.["$(CHAIN)"].isMainnet' deployConfig.json) \
	forge script script/DeployRouter.s.sol:DeployToChain $(COMMON_PARAMS)

wire-up:
	SRC_CHAIN_ID=$$(jq -r '.["$(SRC_CHAIN)"].chainId' deployConfig.json) \
	DST_CHAIN_ID=$$(jq -r '.["$(DST_CHAIN)"].chainId' deployConfig.json) \
	DST_CHAIN_LZ_ID=$$(jq -r '.["$(DST_CHAIN)"].lzId' deployConfig.json) \
	forge script script/WireUpContracts.s.sol:WireUpContracts $(COMMON_PARAMS)

bridge:
	$(eval AMOUNT=$(shell echo "scale=10; $(AMOUNT) * $(DECIMALS)" | bc | sed 's/\..*//'))
	AMOUNT=$(AMOUNT) \
	SRC_CHAIN_ID=$$(jq -r '.["$(SRC_CHAIN)"].chainId' deployConfig.json) \
	DST_CHAIN_ID=$$(jq -r '.["$(DST_CHAIN)"].chainId' deployConfig.json) \
	DST_CHAIN_LZ_ID=$$(jq -r '.["$(DST_CHAIN)"].lzId' deployConfig.json) \
	MAINNET=$$(jq -r '.["$(SRC_CHAIN)"].isMainnet' deployConfig.json) \
	forge script script/BridgeEth.s.sol:BridgeEth $(COMMON_PARAMS)

bridge-e2e:
	CHAIN=$(FIRST_CHAIN) make deploy
	CHAIN=$(SECOND_CHAIN) make deploy
	AMOUNT=0.01 CHAIN=$(FIRST_CHAIN) make add-liquidity
	AMOUNT=0.01 CHAIN=$(SECOND_CHAIN) make add-liquidity
	SRC_CHAIN=$(FIRST_CHAIN) DST_CHAIN=$(SECOND_CHAIN) make wire-up
	SRC_CHAIN=$(SECOND_CHAIN) DST_CHAIN=$(FIRST_CHAIN) make wire-up
	AMOUNT=0.0069 SRC_CHAIN=$(FIRST_CHAIN) DST_CHAIN=$(SECOND_CHAIN) make bridge
	AMOUNT=0.0069 SRC_CHAIN=$(SECOND_CHAIN) DST_CHAIN=$(FIRST_CHAIN) make bridge

wire-up-bridge:
	AMOUNT=0.01 CHAIN=$(FIRST_CHAIN) make add-liquidity
	AMOUNT=0.01 CHAIN=$(SECOND_CHAIN) make add-liquidity
	SRC_CHAIN=$(FIRST_CHAIN) DST_CHAIN=$(SECOND_CHAIN) make wire-up
	SRC_CHAIN=$(SECOND_CHAIN) DST_CHAIN=$(FIRST_CHAIN) make wire-up
	AMOUNT=0.0069 SRC_CHAIN=$(FIRST_CHAIN) DST_CHAIN=$(SECOND_CHAIN) make bridge
	AMOUNT=0.0069 SRC_CHAIN=$(SECOND_CHAIN) DST_CHAIN=$(FIRST_CHAIN) make bridge

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
