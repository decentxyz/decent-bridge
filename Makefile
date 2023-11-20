include .env

COMMON_PARAMS := --broadcast -vvvv --slow

ifeq ($(MAINNET),true)
    COMMON_PARAMS += --private-key=$(MAINNET_ACCOUNT) --verify
else ifeq ($(TESTNET),true)
    COMMON_PARAMS += --private-key=$(TESTNET_ACCOUNT) --verify
else
    COMMON_PARAMS += --unlocked --sender=$(TESTNET_ACCOUNT_ADDRESS)
endif

start-zora:
	$(MAKE) start-forknet CHAINS=ZORA,OPTIMISM

start-chains:
	@. .env && \
	for chain in $(shell echo $(CHAINS) | tr ',' ' '); do \
		rpc_var=$${chain}_RPC; \
		port_var=FORK_$${chain}_PORT; \
		pid_file=$${chain}_PID; \
		echo "chain: $$chain"; \
		echo "rpc_var: $$rpc_var"; \
		rpc_url=$${!rpc_var}; \
		port=$${!port_var}; \
		echo "rpc_url: $$rpc_url"; \
		echo "port: $$port"; \
        anvil --auto-impersonate -f $$rpc_url -p $$port > $$chain.log 2>&1 & \
        echo $$! > $$pid_file ; \
		# Add your commands here using $$chain as the current value; \
	done

stop-chains:
	pkill -f anvil

ANVIL_PRIVATE_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
give-money:
	@. .env && \
	for chain in $(shell echo $(CHAINS) | tr ',' ' '); do \
		port_var=FORK_$${chain}_PORT; \
		port=$${!port_var}; \
		echo "chain: $$chain to: $$to amount: $$amount"; \
		cast send $$to --rpc-url http://localhost:$$port --value "$$amount" --private-key $(ANVIL_PRIVATE_KEY);\
	done

start-forknet:
	$(MAKE) start-chains CHAINS=$(CHAINS);
	sleep 2;
	$(MAKE) give-money CHAINS=$(CHAINS) to=$(TESTNET_ACCOUNT_ADDRESS) amount="900 ether";

copy-addresses:
	cp ./deployments/deployedAddresses.json ~/decentxyz/box-monorepo/apps/box-scenarios/assets/.
	cp ./deployments/deployedAddresses.json ~/decentxyz/box-monorepo/apps/box-api/src/getBoxAction/decentBridge/.
	cp ./deployments/deployedAddresses.json ~/decentxyz/energy-dashboard/constants/.

#deploy-chain:
#	forge script script/Deploy.s.sol:Deploy $(COMMON_PARAMS)
#	$(MAKE) copy-addresses

DECIMALS := 1000000000000000000 # for convenience

add-liquidity:
	$(eval LIQUIDITY=$(shell echo "scale=10; $(amount) * $(DECIMALS)" | bc | sed 's/\..*//'))
	LIQUIDITY=$(LIQUIDITY) \
	forge script script/Deploy.s.sol:AddLiquidity $(COMMON_PARAMS)

bridge:
	$(eval AMOUNT=$(shell echo "scale=10; $(amount) * $(DECIMALS)" | bc | sed 's/\..*//'))
	AMOUNT=$(AMOUNT) \
	forge script script/Deploy.s.sol:Bridge $(COMMON_PARAMS)

deploy-chain:
	forge script script/Deploy.s.sol:Deploy $(COMMON_PARAMS)

wire-up:
	forge script script/Deploy.s.sol:WireUp $(COMMON_PARAMS)

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
