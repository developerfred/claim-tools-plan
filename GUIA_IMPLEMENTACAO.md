# 🚀 Guia de Implementação - ClaimTools.xyz

## 📋 O Que Foi Criado

### Smart Contracts (Solidity)

```
contracts/
├── UniversalClaimHub.sol          # Contrato orquestrador principal
├── modules/
│   ├── ClankerModule.sol          # Módulo Clanker (v1-v4)
│   ├── ZoraModule.sol             # Módulo Zora
│   └── FlaunchModule.sol          # Módulo Flaunch
└── script/
    └── Deploy.s.sol               # Scripts de deploy
```

**Status:** ✅ Contratos completos e prontos para deploy

---

## 🛠️ Setup Rápido

### 1. Setup do Projeto Foundry

```bash
# No diretório do projeto
cd /path/to/claimtools

# Criar estrutura Foundry
mkdir -p contracts
cd contracts
forge init --no-commit

# Copiar contratos
cp /path/to/claim-tools-plan/contracts/* src/
cp /path/to/claim-tools-plan/contracts/modules/* src/modules/
cp /path/to/claim-tools-plan/contracts/script/* script/
```

### 2. Configurar Environment

```bash
# .env
PRIVATE_KEY=your_private_key_here
BASE_RPC_URL=https://mainnet.base.org
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASESCAN_API_KEY=your_basescan_api_key
```

### 3. Compilar Contratos

```bash
forge build

# Verificar compilação
forge build --sizes
```

### 4. Deploy na Testnet (Base Sepolia)

```bash
# Deploy
forge script script/Deploy.s.sol:DeployTestnetScript \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --verify

# Verificar deployment
cat deployments/base-sepolia.json
```

### 5. Deploy na Mainnet (Base)

```bash
# IMPORTANTE: Revisar tudo antes de deploy em mainnet!

forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $BASE_RPC_URL \
  --broadcast \
  --verify

# Salvar endereços
cat deployments/base-mainnet.json
```

---

## 📦 Integração com Frontend

### 1. Instalar Dependências

```bash
cd /path/to/claimtools-frontend

npm install wagmi viem @tanstack/react-query
```

### 2. Criar Arquivo de Configuração

```typescript
// lib/contracts.ts

export const CONTRACTS = {
  // Base Mainnet (Chain ID: 8453)
  8453: {
    UniversalClaimHub: "0x...", // Copiar do deployment
    ClankerModule: "0x...",
    ZoraModule: "0x...",
    FlaunchModule: "0x...",
  },
  // Base Sepolia (Chain ID: 84532)
  84532: {
    UniversalClaimHub: "0x...",
    ClankerModule: "0x...",
    ZoraModule: "0x...",
    FlaunchModule: "0x...",
  }
} as const;

// Protocol addresses
export const PROTOCOL_ADDRESSES = {
  clanker: {
    v4: "0xF3622742b1E446D92e45E22923Ef11C2fcD55D68",
    v31: "0x33e2Eda238edcF470309b8c6D228986A1204c8f9",
  },
  zora: {
    token: "0x1111111111166b7fe7bd91427724b487980afc69",
  },
  flaunch: {
    flay: "0xf1a7000000950c7ad8aff13118bb7ab561a448ee",
  }
} as const;

// Enums
export enum Protocol {
  CLANKER_V4 = 0,
  CLANKER_V31 = 1,
  CLANKER_V3 = 2,
  CLANKER_V2 = 3,
  ZORA = 4,
  FLAUNCH = 5,
  MINT_CLUB = 6,
  AERODROME = 7,
  UNISWAP_V3 = 8,
  UNISWAP_V4 = 9,
}
```

### 3. Gerar ABIs

```bash
# No diretório contracts
forge build

# Copiar ABIs para frontend
mkdir -p ../frontend/lib/abis
cp out/UniversalClaimHub.sol/UniversalClaimHub.json ../frontend/lib/abis/
cp out/ClankerModule.sol/ClankerModule.json ../frontend/lib/abis/
cp out/ZoraModule.sol/ZoraModule.json ../frontend/lib/abis/
cp out/FlaunchModule.sol/FlaunchModule.json ../frontend/lib/abis/
```

### 4. Criar Hooks Wagmi

```typescript
// hooks/useClaimHub.ts

import { useContractRead, useContractWrite, usePrepareContractWrite } from 'wagmi';
import { CONTRACTS } from '@/lib/contracts';
import UniversalClaimHubABI from '@/lib/abis/UniversalClaimHub.json';

export function useClaimHub(chainId: number = 8453) {
  const hubAddress = CONTRACTS[chainId]?.UniversalClaimHub;

  return {
    address: hubAddress,
    abi: UniversalClaimHubABI.abi,
  };
}

// Hook para ver total claimable
export function useTotalClaimable(
  userAddress: string | undefined,
  protocols: number[]
) {
  const { address, abi } = useClaimHub();

  return useContractRead({
    address,
    abi,
    functionName: 'getTotalClaimable',
    args: [userAddress, protocols],
    enabled: !!userAddress && protocols.length > 0,
  });
}

// Hook para batch claim
export function useBatchClaim() {
  const { address, abi } = useClaimHub();

  const { config } = usePrepareContractWrite({
    address,
    abi,
    functionName: 'batchClaimMultiProtocol',
  });

  return useContractWrite(config);
}

// Hook para user stats
export function useUserStats(userAddress: string | undefined) {
  const { address, abi } = useClaimHub();

  return useContractRead({
    address,
    abi,
    functionName: 'getUserStats',
    args: [userAddress],
    enabled: !!userAddress,
  });
}
```

### 5. Componente de Exemplo

```typescript
// components/ClaimDashboard.tsx

'use client';

import { useAccount } from 'wagmi';
import { useTotalClaimable, useBatchClaim, useUserStats } from '@/hooks/useClaimHub';
import { Protocol } from '@/lib/contracts';
import { formatEther } from 'viem';

export function ClaimDashboard() {
  const { address } = useAccount();

  // Protocolos a verificar
  const protocols = [
    Protocol.CLANKER_V4,
    Protocol.ZORA,
    Protocol.FLAUNCH,
  ];

  // Ver total claimable
  const { data: totalClaimable, isLoading } = useTotalClaimable(address, protocols);

  // User stats
  const { data: userStats } = useUserStats(address);

  // Batch claim
  const { write: claimAll, isLoading: isClaiming } = useBatchClaim();

  const handleClaimAll = () => {
    // Construir requests
    const requests = [
      {
        protocol: Protocol.CLANKER_V4,
        tokens: [], // TODO: Buscar tokens do usuário
        extraData: '0x',
      },
      // ... outros protocolos
    ];

    claimAll?.({
      args: [requests],
    });
  };

  if (!address) {
    return (
      <div className="text-center py-12">
        <p>Connect your wallet to see your rewards</p>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="text-center py-12">
        <p>Loading your rewards...</p>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto p-6">
      <div className="bg-white rounded-xl shadow-lg p-6 mb-6">
        <h2 className="text-2xl font-bold mb-4">Total Unclaimed</h2>
        <div className="text-4xl font-bold text-blue-600">
          {totalClaimable ? formatEther(totalClaimable) : '0'} ETH
        </div>

        <button
          onClick={handleClaimAll}
          disabled={isClaiming || !totalClaimable}
          className="mt-4 w-full bg-blue-600 text-white py-3 px-6 rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50"
        >
          {isClaiming ? 'Claiming...' : '🚀 Claim All'}
        </button>
      </div>

      {userStats && (
        <div className="bg-white rounded-xl shadow-lg p-6">
          <h3 className="text-xl font-bold mb-4">Your Stats</h3>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-gray-600">Total Claims</p>
              <p className="text-2xl font-bold">{userStats[0]?.toString()}</p>
            </div>
            {/* Mais stats... */}
          </div>
        </div>
      )}
    </div>
  );
}
```

---

## 🔍 Próximos Passos

### Fase 1: Smart Contracts (Completo ✅)
- [x] UniversalClaimHub
- [x] ClankerModule
- [x] ZoraModule
- [x] FlaunchModule
- [x] Deploy scripts

### Fase 2: Frontend Integration (Próximo)
- [ ] Setup Wagmi + RainbowKit
- [ ] Criar hooks de contract
- [ ] Implementar dashboard UI
- [ ] Token discovery service
- [ ] Transaction preview modal

### Fase 3: Token Discovery (Importante!)
- [ ] Setup The Graph subgraphs
- [ ] Implementar API adapters
- [ ] Cache system (Redis)
- [ ] Discovery service completo

### Fase 4: UX Polish
- [ ] Loading states
- [ ] Error handling
- [ ] Success animations
- [ ] Mobile responsive
- [ ] Dark mode

### Fase 5: Launch
- [ ] Security audit
- [ ] Beta testing
- [ ] Marketing materials
- [ ] Public launch

---

## 📊 Arquitetura Resumida

```
┌─────────────────────────────────┐
│   Frontend (claimtools.xyz)     │
│   Next.js + Wagmi + Tailwind    │
└─────────────┬───────────────────┘
              │
              ▼
┌─────────────────────────────────┐
│   Smart Contracts (Base)        │
│                                  │
│   UniversalClaimHub             │
│   ├── ClankerModule             │
│   ├── ZoraModule                │
│   └── FlaunchModule             │
└─────────────────────────────────┘
```

---

## 🐛 Troubleshooting

### Problema: "Module not found"
```bash
# Verificar se os arquivos estão no lugar certo
ls -la src/
ls -la src/modules/

# Recompilar
forge clean && forge build
```

### Problema: Deploy falha
```bash
# Verificar balance
cast balance $YOUR_ADDRESS --rpc-url $BASE_RPC_URL

# Verificar gas price
cast gas-price --rpc-url $BASE_RPC_URL

# Simular transação
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $BASE_RPC_URL \
  --private-key $PRIVATE_KEY
```

### Problema: Frontend não conecta
```typescript
// Verificar chain ID
import { base, baseSepolia } from 'wagmi/chains';

const chains = [base, baseSepolia];

// Verificar endereço do contrato
console.log('Hub address:', CONTRACTS[chainId]?.UniversalClaimHub);
```

---

## 📚 Recursos

### Documentação
- [Foundry Book](https://book.getfoundry.sh/)
- [Wagmi Docs](https://wagmi.sh/)
- [Viem Docs](https://viem.sh/)
- [Base Docs](https://docs.base.org/)

### Ferramentas
- [Base Explorer](https://basescan.org/)
- [Base Sepolia Explorer](https://sepolia.basescan.org/)
- [Foundry](https://getfoundry.sh/)

---

## ✅ Checklist de Deploy

### Antes do Deploy
- [ ] Compilação sem erros
- [ ] Testes passando
- [ ] Gas optimization review
- [ ] Security review
- [ ] Configurar FEE_COLLECTOR address
- [ ] Configurar PLATFORM_FEE

### Durante Deploy
- [ ] Deploy na testnet primeiro
- [ ] Testar todas as funções
- [ ] Verificar contratos no Basescan
- [ ] Salvar todos os endereços

### Após Deploy
- [ ] Atualizar frontend config
- [ ] Testar integração completa
- [ ] Documentar endereços
- [ ] Criar monitoring

---

## 🎯 Contatos & Suporte

- **Website:** https://claimtools.xyz
- **Docs:** [Este guia]
- **GitHub:** https://github.com/developerfred/claimtools

---

**Pronto para deployar! 🚀**

Próximo passo: Deploy na testnet e testar!
