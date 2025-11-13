# 📍 Referência Rápida - Endereços dos Contratos

## Base Mainnet (Chain ID: 8453)

### Clanker Fee Lockers por Versão

```solidity
// v4.0 - ClankerFeeLocker (Atual)
address constant FEE_LOCKER_V4 = 0xF3622742b1E446D92e45E22923Ef11C2fcD55D68;

// v3.1 - LpLockerv2
address constant LP_LOCKER_V31 = 0x33e2Eda238edcF470309b8c6D228986A1204c8f9;

// v3.0 - LpLockerv2
address constant LP_LOCKER_V30 = 0x5eC4f99F342038c67a312a166Ff56e6D70383D86;

// v2.0 - LpLockerv2
address constant LP_LOCKER_V20 = 0x618A9840691334eE8d24445a4AdA4284Bf42417D;
```

### Clanker Factories (Token Deployers)

```solidity
// v4.0 (Atual)
address constant CLANKER_V4 = 0xE85A59c628F7d27878ACeB4bf3b35733630083a9;

// v3.1
address constant CLANKER_V31 = 0x2A787b2362021cC3eEa3C24C4748a6cD5B687382;

// v3.0
address constant CLANKER_V30 = 0x375C15db32D28cEcdcAB5C03Ab889bf15cbD2c5E;

// v2.0
address constant CLANKER_V20 = 0x732560fa1d1A76350b1A500155BA978031B53833;

// v1.0
address constant CLANKER_V10 = 0x9B84fcE5Dcd9a38d2D01d5D72373F6b6b067c3e1;
```

### Outros Contratos v4.0

```solidity
// LP Locker com conversão de fees
address constant LP_LOCKER_FEE_CONVERSION = 0x63D2DfEA64b3433F4071A98665bcD7Ca14d93496;

// Vault para tokens bloqueados
address constant CLANKER_VAULT_V4 = 0x8E845EAd15737bF71904A30BdDD3aEE76d6ADF6C;

// Airdrop
address constant CLANKER_AIRDROP = 0x56Fa0Da89eD94822e46734e736d34Cab72dF344F;

// Dev Buy helper
address constant UNIV4_ETH_DEV_BUY = 0x1331f0788F9c08C8F38D52c7a1152250A9dE00be;

// MEV Block Delay
address constant MEV_BLOCK_DELAY = 0xE143f9872A33c955F23cF442BB4B1EFB3A7402A2;

// Hooks
address constant HOOK_DYNAMIC_FEE = 0x34a45c6B61876d739400Bd71228CbcbD4F53E8cC;
address constant HOOK_STATIC_FEE = 0xDd5EeaFf7BD481AD55Db083062b13a3cdf0A68CC;
```

## Base Sepolia (Chain ID: 84532) - Testnet

### Fee Lockers Testnet

```solidity
// v4.0
address constant FEE_LOCKER_V4_TESTNET = 0x42A95190B4088C88Dd904d930c79deC1158bF09D;

// v3.1
address constant LP_LOCKER_V31_TESTNET = 0x33e2Eda238edcF470309b8c6D228986A1204c8f9;
```

## Outros Tokens Importantes na Base

```solidity
// WETH (Wrapped ETH)
address constant WETH = 0x4200000000000000000000000000000000000006;

// CLANKER Token
address constant CLANKER_TOKEN = 0x1bc0c42215582d5a085795f4badbac3ff36d1bcb;

// USDC
address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
```

## RPC Endpoints

```bash
# Base Mainnet
https://mainnet.base.org
https://base.llamarpc.com
https://base-mainnet.public.blastapi.io

# Base Sepolia (Testnet)
https://sepolia.base.org
```

## Exploradores

```
# Basescan
https://basescan.org

# Base Sepolia
https://sepolia.basescan.org
```

## APIs

```
# Clanker API
https://api.clanker.world

# Exemplos:
GET https://api.clanker.world/tokens
GET https://api.clanker.world/tokens/{address}
```

## Uniswap V3 (usado por v3.x)

```solidity
// Position Manager
address constant UNISWAP_V3_POS_MANAGER = 0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1;

// Factory
address constant UNISWAP_V3_FACTORY = 0x33128a8fC17869897dcE68Ed026d694621f6FDfD;

// Router
address constant UNISWAP_V3_ROUTER = 0x2626664c2603336E57B271c5C0b26F421741e481;
```

## Uniswap V4 (usado por v4.0)

```solidity
// Pool Manager
address constant UNISWAP_V4_POOL_MANAGER = 0x7Da1D65F8B249183667cdE74C5CBD46dD38AA829;
```

## Como Usar

### JavaScript/TypeScript

```javascript
const ADDRESSES = {
  FEE_LOCKER_V4: '0xF3622742b1E446D92e45E22923Ef11C2fcD55D68',
  LP_LOCKER_V31: '0x33e2Eda238edcF470309b8c6D228986A1204c8f9',
  // ...
};

const contract = new ethers.Contract(
  ADDRESSES.FEE_LOCKER_V4,
  ABI,
  signer
);
```

### Hardhat Config

```javascript
module.exports = {
  networks: {
    base: {
      url: "https://mainnet.base.org",
      chainId: 8453,
      accounts: [process.env.PRIVATE_KEY]
    }
  }
};
```

### Foundry Config

```toml
[rpc_endpoints]
base = "https://mainnet.base.org"
base_sepolia = "https://sepolia.base.org"

[etherscan]
base = { key = "${BASESCAN_API_KEY}", url = "https://api.basescan.org/api" }
```

## Verificação de Contratos

```bash
# Basescan API Key
https://basescan.org/myapikey

# Verificar contrato
forge verify-contract \
  --chain-id 8453 \
  --etherscan-api-key $BASESCAN_API_KEY \
  <CONTRACT_ADDRESS> \
  <CONTRACT_NAME>
```

## Faucets (Testnet)

```
# Base Sepolia ETH
https://www.coinbase.com/faucets/base-ethereum-goerli-faucet

# Alchemy Faucet
https://www.alchemy.com/faucets/base-sepolia
```

---

**💡 Dica**: Salve este arquivo como referência rápida durante o desenvolvimento!
