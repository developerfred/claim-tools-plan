# 🎨 Frontend Integration Guide - ClaimTools.xyz

## 📋 Overview

Este guia mostra como integrar os smart contracts do ClaimTools com seu frontend Next.js existente.

**Assumindo que você já tem:**
- ✅ Next.js app rodando
- ✅ Domínio claimtools.xyz configurado
- ✅ UI básica implementada

**Vamos adicionar:**
- 🔗 Integração com smart contracts (Wagmi)
- 📊 Token discovery
- ⚡ Batch claiming
- 💎 UX completa

---

## 🚀 Step-by-Step

### Step 1: Instalar Dependências

```bash
cd /path/to/claimtools-frontend

npm install wagmi viem @tanstack/react-query
npm install @rainbow-me/rainbowkit # Opcional, mas recomendado
```

### Step 2: Copiar Arquivos de Configuração

```bash
# Copiar config example
cp /path/to/claim-tools-plan/frontend-config-example.ts lib/contracts.ts

# Criar pasta para ABIs
mkdir -p lib/abis
```

### Step 3: Extrair ABIs dos Contratos

```bash
# No diretório dos contratos
cd /path/to/contracts
forge build

# Copiar ABIs para frontend
cp out/UniversalClaimHub.sol/UniversalClaimHub.json ../claimtools-frontend/lib/abis/
cp out/ClankerModule.sol/ClankerModule.json ../claimtools-frontend/lib/abis/
cp out/ZoraModule.sol/ZoraModule.json ../claimtools-frontend/lib/abis/
cp out/FlaunchModule.sol/FlaunchModule.json ../claimtools-frontend/lib/abis/
```

### Step 4: Atualizar Endereços dos Contratos

Após fazer deploy dos contratos, atualizar `lib/contracts.ts`:

```typescript
// lib/contracts.ts

export const CONTRACTS = {
  8453: {  // Base Mainnet
    UniversalClaimHub: '0xYOUR_HUB_ADDRESS' as Address,
    ClankerModule: '0xYOUR_CLANKER_MODULE' as Address,
    ZoraModule: '0xYOUR_ZORA_MODULE' as Address,
    FlaunchModule: '0xYOUR_FLAUNCH_MODULE' as Address,
  },
  // ...
}
```

---

## 🔧 Criar Hooks

### Hook 1: useClaimHub

```typescript
// hooks/useClaimHub.ts

import { useContractRead, useContractWrite } from 'wagmi';
import { useAccount } from 'wagmi';
import { CONTRACTS } from '@/lib/contracts';
import UniversalClaimHubABI from '@/lib/abis/UniversalClaimHub.json';

export function useClaimHub() {
  const { chainId } = useAccount();
  const hubAddress = CONTRACTS[chainId as keyof typeof CONTRACTS]?.UniversalClaimHub;

  return {
    address: hubAddress,
    abi: UniversalClaimHubABI.abi,
  };
}
```

### Hook 2: useTotalClaimable

```typescript
// hooks/useTotalClaimable.ts

import { useContractRead } from 'wagmi';
import { useAccount } from 'wagmi';
import { useClaimHub } from './useClaimHub';
import { Protocol } from '@/lib/contracts';

export function useTotalClaimable() {
  const { address } = useAccount();
  const { address: hubAddress, abi } = useClaimHub();

  // Protocolos a verificar
  const protocols = [
    Protocol.CLANKER_V4,
    Protocol.ZORA,
    Protocol.FLAUNCH,
  ];

  return useContractRead({
    address: hubAddress,
    abi,
    functionName: 'getTotalClaimable',
    args: [address, protocols],
    enabled: !!address,
    watch: true, // Auto-refresh
  });
}
```

### Hook 3: useBatchClaim

```typescript
// hooks/useBatchClaim.ts

import { useContractWrite, usePrepareContractWrite, useWaitForTransaction } from 'wagmi';
import { useClaimHub } from './useClaimHub';
import type { ClaimRequest } from '@/lib/contracts';

export function useBatchClaim() {
  const { address: hubAddress, abi } = useClaimHub();

  const { config, error: prepareError } = usePrepareContractWrite({
    address: hubAddress,
    abi,
    functionName: 'batchClaimMultiProtocol',
  });

  const {
    data,
    write,
    error: writeError,
    isLoading: isWriting
  } = useContractWrite(config);

  const {
    isLoading: isConfirming,
    isSuccess
  } = useWaitForTransaction({
    hash: data?.hash,
  });

  return {
    claim: write,
    isLoading: isWriting || isConfirming,
    isSuccess,
    error: prepareError || writeError,
    txHash: data?.hash,
  };
}
```

### Hook 4: useUserStats

```typescript
// hooks/useUserStats.ts

import { useContractRead } from 'wagmi';
import { useAccount } from 'wagmi';
import { useClaimHub } from './useClaimHub';

export function useUserStats() {
  const { address } = useAccount();
  const { address: hubAddress, abi } = useClaimHub();

  return useContractRead({
    address: hubAddress,
    abi,
    functionName: 'getUserStats',
    args: [address],
    enabled: !!address,
  });
}
```

---

## 🎨 Componentes UI

### Componente 1: ClaimDashboard

```typescript
// components/ClaimDashboard.tsx

'use client';

import { useState } from 'react';
import { useAccount } from 'wagmi';
import { formatEther } from 'viem';
import { useTotalClaimable } from '@/hooks/useTotalClaimable';
import { useBatchClaim } from '@/hooks/useBatchClaim';
import { useUserStats } from '@/hooks/useUserStats';
import { Protocol, buildClaimRequest } from '@/lib/contracts';

export function ClaimDashboard() {
  const { address, isConnected } = useAccount();
  const { data: totalClaimable, isLoading: loadingClaimable } = useTotalClaimable();
  const { data: userStats } = useUserStats();
  const { claim, isLoading: isClaiming, isSuccess, txHash } = useBatchClaim();

  const handleClaimAll = async () => {
    // TODO: Buscar tokens do usuário via discovery service
    const userTokens = await fetchUserTokens(address);

    // Construir requests por protocolo
    const requests = [
      buildClaimRequest(Protocol.CLANKER_V4, userTokens.clanker),
      buildClaimRequest(Protocol.ZORA, userTokens.zora),
      buildClaimRequest(Protocol.FLAUNCH, userTokens.flaunch),
    ];

    claim?.({ args: [requests] });
  };

  if (!isConnected) {
    return (
      <div className="text-center py-12">
        <p className="text-lg text-gray-600">
          Connect your wallet to see your rewards
        </p>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto p-6">
      {/* Total Unclaimed Card */}
      <div className="bg-gradient-to-r from-blue-500 to-purple-600 rounded-2xl shadow-xl p-8 mb-6 text-white">
        <h2 className="text-xl font-semibold mb-2">Total Unclaimed Rewards</h2>

        {loadingClaimable ? (
          <div className="animate-pulse">
            <div className="h-12 bg-white/20 rounded w-48"></div>
          </div>
        ) : (
          <div className="text-5xl font-bold mb-4">
            {totalClaimable ? formatEther(totalClaimable) : '0'} ETH
          </div>
        )}

        <button
          onClick={handleClaimAll}
          disabled={isClaiming || !totalClaimable}
          className="w-full bg-white text-blue-600 py-4 px-6 rounded-xl font-bold text-lg hover:bg-blue-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isClaiming ? '⏳ Claiming...' : '🚀 Claim All Rewards'}
        </button>

        {isSuccess && txHash && (
          <div className="mt-4 p-4 bg-green-500/20 rounded-lg">
            <p className="text-sm">
              ✅ Success!
              <a
                href={`https://basescan.org/tx/${txHash}`}
                target="_blank"
                rel="noopener noreferrer"
                className="underline ml-2"
              >
                View transaction
              </a>
            </p>
          </div>
        )}
      </div>

      {/* User Stats Card */}
      {userStats && (
        <div className="bg-white rounded-2xl shadow-lg p-6">
          <h3 className="text-xl font-bold mb-4">Your Statistics</h3>

          <div className="grid grid-cols-2 md:grid-cols-3 gap-6">
            <div>
              <p className="text-gray-600 text-sm mb-1">Total Claims</p>
              <p className="text-3xl font-bold text-blue-600">
                {userStats[0]?.toString()}
              </p>
            </div>

            {/* Mais stats por protocolo */}
            <div>
              <p className="text-gray-600 text-sm mb-1">Clanker</p>
              <p className="text-3xl font-bold text-purple-600">
                {formatEther(userStats[1]?.[Protocol.CLANKER_V4] || 0n)}
              </p>
            </div>

            <div>
              <p className="text-gray-600 text-sm mb-1">Zora</p>
              <p className="text-3xl font-bold text-pink-600">
                {formatEther(userStats[1]?.[Protocol.ZORA] || 0n)}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// Helper function (implementar no backend)
async function fetchUserTokens(address: string) {
  // TODO: Implementar discovery service
  return {
    clanker: [],
    zora: [],
    flaunch: [],
  };
}
```

### Componente 2: ConnectButton

```typescript
// components/ConnectButton.tsx

'use client';

import { ConnectButton as RainbowConnectButton } from '@rainbow-me/rainbowkit';

export function ConnectButton() {
  return (
    <RainbowConnectButton
      chainStatus="icon"
      showBalance={false}
    />
  );
}
```

---

## ⚙️ Configuração Wagmi

### app/providers.tsx

```typescript
'use client';

import { WagmiConfig, createConfig, configureChains } from 'wagmi';
import { base, baseSepolia } from 'wagmi/chains';
import { alchemyProvider } from 'wagmi/providers/alchemy';
import { publicProvider } from 'wagmi/providers/public';
import { RainbowKitProvider, getDefaultWallets } from '@rainbow-me/rainbowkit';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

import '@rainbow-me/rainbowkit/styles.css';

const { chains, publicClient } = configureChains(
  [base, baseSepolia],
  [
    alchemyProvider({ apiKey: process.env.NEXT_PUBLIC_ALCHEMY_KEY! }),
    publicProvider(),
  ]
);

const { connectors } = getDefaultWallets({
  appName: 'ClaimTools',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID!,
  chains,
});

const wagmiConfig = createConfig({
  autoConnect: true,
  connectors,
  publicClient,
});

const queryClient = new QueryClient();

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WagmiConfig config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider chains={chains}>
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiConfig>
  );
}
```

### app/layout.tsx

```typescript
import { Providers } from './providers';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
```

---

## 🔍 Token Discovery Service

### services/tokenDiscovery.ts

```typescript
// services/tokenDiscovery.ts

import { Address } from 'viem';
import { Protocol } from '@/lib/contracts';

export interface UserTokens {
  clanker: Address[];
  zora: Address[];
  flaunch: Address[];
}

/**
 * Discover all tokens for a user
 * TODO: Implementar com The Graph ou APIs
 */
export async function discoverUserTokens(
  userAddress: Address
): Promise<UserTokens> {
  // Parallel fetch de todas as fontes
  const [clankerTokens, zoraTokens, flaunchTokens] = await Promise.all([
    fetchClankerTokens(userAddress),
    fetchZoraTokens(userAddress),
    fetchFlaunchTokens(userAddress),
  ]);

  return {
    clanker: clankerTokens,
    zora: zoraTokens,
    flaunch: flaunchTokens,
  };
}

async function fetchClankerTokens(userAddress: Address): Promise<Address[]> {
  // TODO: Implementar com Clanker API ou The Graph
  try {
    const response = await fetch(
      `https://api.clanker.world/tokens?creator=${userAddress}`
    );
    const data = await response.json();
    return data.tokens.map((t: any) => t.address as Address);
  } catch (error) {
    console.error('Error fetching Clanker tokens:', error);
    return [];
  }
}

async function fetchZoraTokens(userAddress: Address): Promise<Address[]> {
  // TODO: Implementar com Zora API
  try {
    const response = await fetch(
      `https://api.zora.co/v1/tokens?creator=${userAddress}&chain=base`
    );
    const data = await response.json();
    return data.tokens.map((t: any) => t.address as Address);
  } catch (error) {
    console.error('Error fetching Zora tokens:', error);
    return [];
  }
}

async function fetchFlaunchTokens(userAddress: Address): Promise<Address[]> {
  // TODO: Implementar com The Graph subgraph
  return [];
}
```

---

## ✅ Checklist de Integração

### Setup Inicial
- [ ] Instalar dependências (wagmi, viem, react-query)
- [ ] Copiar arquivos de configuração
- [ ] Extrair ABIs dos contratos
- [ ] Configurar Wagmi providers

### Contratos
- [ ] Atualizar endereços após deploy
- [ ] Testar conexão com contratos
- [ ] Verificar ABIs corretas

### Hooks
- [ ] Implementar useClaimHub
- [ ] Implementar useTotalClaimable
- [ ] Implementar useBatchClaim
- [ ] Implementar useUserStats

### UI Components
- [ ] ClaimDashboard component
- [ ] Connect wallet button
- [ ] Transaction status UI
- [ ] Loading states

### Discovery
- [ ] Token discovery service
- [ ] API integrations
- [ ] Cache system (opcional)

### Testing
- [ ] Testar em testnet
- [ ] Testar todos os fluxos
- [ ] Mobile testing
- [ ] Error handling

---

## 🐛 Troubleshooting

### "Contract not found"
- Verificar se endereços estão corretos em `lib/contracts.ts`
- Verificar se está na chain correta (Base = 8453)

### "Transaction failed"
- Verificar allowances se necessário
- Verificar balance de gas
- Verificar se tem rewards para claimar

### "Hook error"
- Verificar se ABI está correto
- Verificar se função existe no contrato
- Ver console para erro específico

---

## 📚 Recursos

- [Wagmi Docs](https://wagmi.sh/)
- [Viem Docs](https://viem.sh/)
- [RainbowKit Docs](https://www.rainbowkit.com/)
- [Base Docs](https://docs.base.org/)

---

**Pronto para integrar! 🚀**

Próximo: Implementar discovery service e testar!
