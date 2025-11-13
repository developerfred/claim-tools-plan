# Clanker Universal Batch Claim - Guia de Deploy e Uso

## 📋 Sobre

Contrato UNIVERSAL otimizado para fazer claim de múltiplos rewards de **TODAS AS VERSÕES** do Clanker (v1.0, v2.0, v3.0, v3.1, v4.0) em uma única transação na Base Network.

## ⚠️ IMPORTANTE: Diferenças entre Versões

O Clanker possui várias versões com contratos diferentes:

### Versão 4.0 (Atual - Recomendada)
- **Contrato**: `ClankerFeeLocker` em `0xF3622742b1E446D92e45E22923Ef11C2fcD55D68`
- ✅ Permite visualizar rewards antes do claim
- ✅ Claim de qualquer usuário para qualquer feeOwner
- ✅ Mais eficiente em gas
- **Tokens**: Deployados após Julho 2025

### Versão 3.1
- **Contrato**: `LpLockerv2` em `0x33e2Eda238edcF470309b8c6D228986A1204c8f9`
- ❌ Não tem função view para ver rewards
- ⚠️ Só o dono do token pode fazer claim
- **Tokens**: Deployados entre Março-Julho 2025

### Versões Antigas (3.0, 2.0, 1.0)
- Usam contratos `LpLockerv2` diferentes
- ❌ Sem visualização de rewards
- **Tokens**: Deployados antes de Março 2025

## 🎯 Funcionalidades

1. **✅ Suporte Universal** - Funciona com TODAS as versões do Clanker
2. **📊 Visualizar Rewards** - Ver saldos não reclamados (v4 apenas)
3. **⚡ Batch Claim** - Reclamar múltiplos rewards em uma transação
4. **🎯 Claim por Versão** - Especificar versão de cada token
5. **💰 Gas Otimizado** - Implementação eficiente

## 📍 Endereços dos Contratos na Base

### Fee Lockers por Versão
- **v4.0**: `0xF3622742b1E446D92e45E22923Ef11C2fcD55D68` (ClankerFeeLocker)
- **v3.1**: `0x33e2Eda238edcF470309b8c6D228986A1204c8f9` (LpLockerv2)
- **v3.0**: `0x5eC4f99F342038c67a312a166Ff56e6D70383D86` (LpLockerv2)
- **v2.0**: `0x618A9840691334eE8d24445a4AdA4284Bf42417D` (LpLockerv2)

### Seu Contrato (após deploy)
- **ClankerUniversalBatchClaim**: `[Seu endereço]`

## 🚀 Deploy

### Usando Foundry

```bash
# Instalar Foundry (se ainda não tiver)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Criar projeto
forge init clanker-batch-claim
cd clanker-batch-claim

# Copiar o contrato para src/
cp ClankerBatchClaim.sol src/

# Deploy na Base
forge create --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY \
  --etherscan-api-key $BASESCAN_API_KEY \
  --verify \
  src/ClankerBatchClaim.sol:ClankerBatchClaim
```

### Usando Hardhat

```javascript
// hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    base: {
      url: "https://mainnet.base.org",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 8453
    }
  },
  etherscan: {
    apiKey: {
      base: process.env.BASESCAN_API_KEY
    }
  }
};

// scripts/deploy.js
async function main() {
  const ClankerBatchClaim = await ethers.getContractFactory("ClankerBatchClaim");
  const contract = await ClankerBatchClaim.deploy();
  await contract.deployed();
  
  console.log("ClankerBatchClaim deployed to:", contract.address);
  
  // Verificar no Basescan
  await run("verify:verify", {
    address: contract.address,
    constructorArguments: []
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

## 💡 Exemplos de Uso

### Como Descobrir a Versão do Seu Token?

Use a API do Clanker ou verifique a data de deployment:
- **Após Julho 2025**: v4.0
- **Março-Julho 2025**: v3.1
- **Antes de Março 2025**: v3.0 ou anterior

```javascript
// Consultando via API
const response = await fetch(`https://api.clanker.world/tokens/${tokenAddress}`);
const data = await response.json();
console.log("Version:", data.version); // "v4.0.0" ou "v3.1.0"
```

### 1. Visualizar Rewards (v4 apenas)

```javascript
const { ethers } = require("ethers");

const CONTRACT_ADDRESS = "0x..."; // Seu contrato
const provider = new ethers.providers.JsonRpcProvider("https://mainnet.base.org");
const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, provider);

// Ver rewards v4
const tokensV4 = [
  "0x...", // Seus tokens v4
];

const rewards = await contract.getAvailableRewardsV4(userAddress, tokensV4);

rewards.forEach(r => {
  console.log(`Token: ${r.token}`);
  console.log(`Amount: ${ethers.utils.formatEther(r.amount)}`);
  console.log(`Version: V4`);
});
```

### 2. Claim Universal (Todas as Versões)

```javascript
const signer = new ethers.Wallet(PRIVATE_KEY, provider);
const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);

// Enum das versões
const ClankerVersion = {
  V1: 0,
  V2: 1,
  V3: 2,
  V31: 3,
  V4: 4
};

// Array com tokens de diferentes versões
const claims = [
  {
    token: "0x...", // Token v4
    version: ClankerVersion.V4
  },
  {
    token: "0x...", // Token v3.1
    version: ClankerVersion.V31
  },
  {
    token: "0x...", // Outro token v4
    version: ClankerVersion.V4
  }
];

try {
  const tx = await contract.universalBatchClaim(claims);
  console.log("Transaction:", tx.hash);
  
  const receipt = await tx.wait();
  console.log("Gas usado:", receipt.gasUsed.toString());
  
  // Ver eventos
  const event = receipt.events?.find(e => e.event === "RewardsClaimed");
  if (event) {
    console.log("Tokens:", event.args.tokens);
    console.log("Amounts:", event.args.amounts);
    console.log("Versions:", event.args.versions);
  }
} catch (error) {
  console.error("Erro:", error);
}
```

### 3. Claim Apenas v4 (Mais Eficiente)

```javascript
// Se você só tem tokens v4, use esta função otimizada
const tokensV4 = [
  "0x...",
  "0x..."
];

const tx = await contract.batchClaimV4(tokensV4);
await tx.wait();
```

### 4. Claim Apenas v3.1

```javascript
const tokensV31 = [
  "0x...",
  "0x..."
];

const tx = await contract.batchClaimV31(tokensV31);
await tx.wait();
```

### 5. Claim de Um Único Token

```javascript
// Especificando a versão
const token = "0x...";
const version = ClankerVersion.V4; // ou V31, V3, etc.

const tx = await contract.claimSingle(token, version);
await tx.wait();
```

### 6. Verificar Rewards v4

```javascript
const amount = await contract.checkRewardsV4(userAddress, tokenAddress);
console.log(`Rewards: ${ethers.utils.formatEther(amount)}`);
```

## 🔧 Integração React + Wagmi (v4)

```typescript
import { useContractRead, useContractWrite } from 'wagmi';

// Hook para ver rewards v4
function useRewardsV4(userAddress: string, tokens: string[]) {
  return useContractRead({
    address: CONTRACT_ADDRESS,
    abi: ABI,
    functionName: 'getAvailableRewardsV4',
    args: [userAddress, tokens],
    enabled: !!userAddress && tokens.length > 0
  });
}

// Hook para claim universal
function useUniversalClaim() {
  const { config } = usePrepareContractWrite({
    address: CONTRACT_ADDRESS,
    abi: ABI,
    functionName: 'universalBatchClaim'
  });

  return useContractWrite(config);
}

// Componente
function ClaimDashboard() {
  const { address } = useAccount();
  
  // Separar tokens por versão
  const [v4Tokens, setV4Tokens] = useState([]);
  const [v31Tokens, setV31Tokens] = useState([]);
  
  const { data: v4Rewards } = useRewardsV4(address, v4Tokens);
  const { write: claimAll } = useUniversalClaim();
  
  const handleClaimAll = () => {
    const claims = [
      ...v4Tokens.map(token => ({ token, version: 4 })),
      ...v31Tokens.map(token => ({ token, version: 3 }))
    ];
    
    claimAll?.({ args: [claims] });
  };
  
  return (
    <div>
      <h2>Seus Rewards</h2>
      
      <div>
        <h3>V4 Tokens</h3>
        {v4Rewards?.map((r, i) => (
          <div key={i}>
            <p>Token: {r.token}</p>
            <p>Amount: {formatEther(r.amount)}</p>
          </div>
        ))}
      </div>
      
      <button onClick={handleClaimAll}>
        Claim All Versions
      </button>
    </div>
  );
}
```

## ⚡ Otimizações de Gas

1. **Uso de `unchecked`** - Loops otimizados sem verificação de overflow
2. **Pré-filtragem** - Verifica saldo antes de tentar claim
3. **Batch Processing** - Múltiplos claims em uma transação
4. **Try-Catch Seletivo** - Continua mesmo se um claim falhar
5. **Calldata** - Uso de calldata ao invés de memory quando possível

## 🛡️ Segurança

- ✅ Sem funções de transferência de tokens do contrato
- ✅ Sem permissões de admin
- ✅ Imutável após deploy
- ✅ Claims sempre vão para msg.sender
- ✅ Não armazena fundos

## 📊 Estimativa de Gas

| Operação | Gas Estimado |
|----------|--------------|
| Visualizar rewards (5 tokens) | ~50,000 |
| Claim 1 token | ~80,000 |
| Batch claim 5 tokens | ~250,000 |
| Batch claim available (5 tokens) | ~200,000 |

## 📝 ABI

```json
[
  {
    "inputs": [
      {
        "internalType": "address[]",
        "name": "tokens",
        "type": "address[]"
      }
    ],
    "name": "batchClaim",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "successCount",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address[]",
        "name": "tokens",
        "type": "address[]"
      }
    ],
    "name": "batchClaimAvailable",
    "outputs": [
      {
        "internalType": "address[]",
        "name": "claimedTokens",
        "type": "address[]"
      },
      {
        "internalType": "uint256[]",
        "name": "claimedAmounts",
        "type": "uint256[]"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "internalType": "address[]",
        "name": "tokens",
        "type": "address[]"
      }
    ],
    "name": "getAvailableRewards",
    "outputs": [
      {
        "components": [
          {
            "internalType": "address",
            "name": "token",
            "type": "address"
          },
          {
            "internalType": "uint256",
            "name": "amount",
            "type": "uint256"
          }
        ],
        "internalType": "struct ClankerBatchClaim.UnclaimedReward[]",
        "name": "availableRewards",
        "type": "tuple[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
]
```

## 🔗 Links Úteis

- [Documentação Clanker](https://clanker.gitbook.io/clanker-documentation/)
- [Base Network](https://base.org)
- [Basescan](https://basescan.org)
- [Clanker.world](https://clanker.world)

## ⚠️ Avisos

- Sempre teste primeiro na testnet
- Verifique os endereços dos tokens antes do claim
- Mantenha uma margem de gas para evitar falhas
- Rewards vão diretamente para sua carteira (msg.sender)
