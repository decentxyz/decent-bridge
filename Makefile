include .env

.phony: deploy-chain

COMMON_PARAMS := --broadcast -vvvv

ifeq ($(MAINNET),true)
    COMMON_PARAMS += --private-key=$(MAINNET_ACCOUNT) --verify --slow
else ifeq ($(TESTNET),true)
    COMMON_PARAMS += --private-key=$(TESTNET_ACCOUNT) --verify --slow
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

#copy-addresses:
#	cp ./deployments/deployedAddresses.json ~/decentxyz/box-monorepo/apps/box-scenarios/assets/.
#	cp ./deployments/deployedAddresses.json ~/decentxyz/box-monorepo/apps/box-api/src/getBoxAction/decentBridge/.
#	cp ./deployments/deployedAddresses.json ~/decentxyz/energy-dashboard/constants/.

DECIMALS := 1000000000000000000 # for convenience

add-liquidity:
	$(eval LIQUIDITY=$(shell echo "scale=10; $(amount) * $(DECIMALS)" | bc | sed 's/\..*//'))
	LIQUIDITY=$(LIQUIDITY) \
	forge script script/Scripts.s.sol:AddLiquidity $(COMMON_PARAMS)

bridge:
	$(eval AMOUNT=$(shell echo "scale=10; $(amount) * $(DECIMALS)" | bc | sed 's/\..*//'))
	AMOUNT=$(AMOUNT) \
	forge script script/Scripts.s.sol:Bridge $(COMMON_PARAMS)

deploy-chain:
	forge script script/Scripts.s.sol:Deploy $(COMMON_PARAMS)

wire-up:
	forge script script/Scripts.s.sol:WireUp $(COMMON_PARAMS)

bridge-e2e:
	$(MAKE) deploy-chain chain=$(src)
	$(MAKE) deploy-chain chain=$(dst)
	$(MAKE) wire-up src=$(src) dst=$(dst)
	$(MAKE) wire-up src=$(dst) dst=$(src)
	$(MAKE) add-liquidity chain=$(src) amount=0.01
	$(MAKE) add-liquidity chain=$(dst) amount=0.01
	$(MAKE) bridge amount=0.0069 src=$(src) dst=$(dst)
	$(MAKE) bridge amount=0.0069 src=$(dst) dst=$(src)

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
