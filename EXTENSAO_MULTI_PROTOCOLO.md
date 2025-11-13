# 🚀 Extensão Multi-Protocolo - Plano Completo 2025

## 📋 Sumário Executivo

Este documento estende o plano original focado em Clanker para criar uma **plataforma unificada de claim de rewards** que suporta múltiplos protocolos de token launch na Base Network, com descoberta automática de tokens e UX suprema.

## 🎯 Visão Geral

### O Que Estamos Criando

Uma **plataforma universal** que permite aos usuários:
1. ✅ Descobrir TODOS os tokens que criaram/possuem com apenas seu endereço
2. ✅ Ver rewards de MÚLTIPLOS protocolos em um único dashboard
3. ✅ Fazer claim de tudo em UMA transação otimizada
4. ✅ Acompanhar analytics e performance cross-protocol

### Por Que Isso É Revolucionário

```
Antes:
❌ 5+ sites diferentes (Clanker, Zora, Flaunch, etc.)
❌ Logar em cada um separadamente
❌ Descobrir manualmente seus tokens
❌ Múltiplas transações, alto custo de gas
❌ Nenhuma visão consolidada

Depois:
✅ UM dashboard unificado
✅ Descoberta automática via endereço
✅ UMA transação para tudo
✅ 80%+ economia de gas
✅ Analytics completo cross-protocol
```

---

## 🏗️ Protocolos Suportados

### 1. **Clanker** (Já Implementado)
```yaml
Tipo: AI Token Launchpad
Versões: v1.0, v2.0, v3.0, v3.1, v4.0
Fee Locker v4: 0xF3622742b1E446D92e45E22923Ef11C2fcD55D68
Fee Locker v3.1: 0x33e2Eda238edcF470309b8c6D228986A1204c8f9
Factory v4: 0xE85A59c628F7d27878ACeB4bf3b35733630083a9
Rewards: Sim (trading fees)
Status: ✅ Implementado
```

**Features:**
- Claim de rewards de trading fees
- Suporte a múltiplas versões
- Batch claiming otimizado

---

### 2. **Zora** (NOVO)
```yaml
Tipo: Creator Token Launchpad
Token: ZORA (0x1111111111166b7fe7bd91427724b487980afc69)
Network: Base
Lançamento: Primavera 2025
Total Supply: 10 bilhões
Fees: 1% trading fee (50% para criadores)
Status: 🆕 A implementar
```

**Features:**
- Tokens ERC-20 com 1 bilhão de supply padrão
- 50% das trading fees vão para criadores
- Integração com NFTs da Zora
- Sistema de royalties para criadores

**O Que Precisamos Implementar:**
```solidity
// Descoberta de tokens Zora
function discoverZoraTokens(address creator)
    returns (address[] memory tokens)

// Ver rewards não reclamados
function getZoraRewards(address creator, address[] tokens)
    returns (uint256[] memory rewards)

// Batch claim Zora
function batchClaimZoraRewards(address[] tokens)
```

---

### 3. **Flaunch** (NOVO)
```yaml
Tipo: Uniswap V4 Memecoin Launchpad
Token: FLAY (0xf1a7000000950c7ad8aff13118bb7ab561a448ee)
Network: Base, Ethereum, Arbitrum
Lançamento: Janeiro 30, 2025
Features: Buybacks automáticos, NFT ownership, Fee splits
Status: 🆕 A implementar
```

**Características Únicas:**
- 100% das trading fees vão para desenvolvedores
- Price lock de ~30 minutos no lançamento
- Buybacks automáticos a cada 0.1 ETH em fees
- NFT que representa ownership do token
- Uniswap V4 hooks customizados

**O Que Precisamos Implementar:**
```solidity
// Descoberta de tokens Flaunch
function discoverFlaunchTokens(address creator)
    returns (address[] memory tokens, uint256[] memory nftIds)

// Ver fees acumuladas
function getFlaunchFees(address[] tokens)
    returns (uint256[] memory fees)

// Claim fees + trigger buyback
function batchClaimFlaunchFees(address[] tokens, bool triggerBuyback)

// Ver NFT ownership
function getFlaunchNFTOwnership(address owner)
    returns (uint256[] memory nftIds, address[] memory tokens)
```

---

### 4. **Mint Club** (NOVO)
```yaml
Tipo: Bonding Curve Token Launch
Network: Base (+ outras)
Mecanismo: Bonding curves com tokens ERC-20
Liquidez: Auto-gerenciada on-chain
Status: 🆕 A implementar
```

**Características:**
- Tokens lastreados por outros ERC-20
- Bonding curve automática para pricing
- Liquidez sempre disponível
- Sem necessidade de LP manual

**O Que Precisamos Implementar:**
```solidity
// Descoberta de tokens Mint Club
function discoverMintClubTokens(address creator)
    returns (address[] memory tokens, address[] memory backingTokens)

// Ver fees/rewards do bonding curve
function getMintClubRewards(address creator, address[] tokens)
    returns (uint256[] memory rewards)

// Batch claim
function batchClaimMintClubRewards(address[] tokens)
```

---

### 5. **Aerodrome Finance** (NOVO)
```yaml
Tipo: DEX/AMM (Liquidez Provider)
Network: Base
Tipo: Liquidity hub central do Base
TVL: Parte dos $11.6B+ do Base
Status: 🆕 A implementar (para LPs)
```

**O Que Precisamos Implementar:**
```solidity
// Descoberta de LP positions
function discoverAerodromePositions(address user)
    returns (uint256[] memory positionIds)

// Ver fees não reclamadas
function getAerodromeFees(uint256[] positionIds)
    returns (uint256[] memory fees)

// Batch claim LP fees
function batchClaimAerodromeFees(uint256[] positionIds)
```

---

### 6. **Uniswap V3/V4** (NOVO)
```yaml
Tipo: DEX/AMM
Versões: V3 (usado por Clanker v3.x), V4 (usado por Flaunch)
V3 Position Manager: 0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1
V3 Factory: 0x33128a8fC17869897dcE68Ed026d694621f6FDfD
V4 Pool Manager: 0x7Da1D65F8B249183667cdE74C5CBD46dD38AA829
Status: 🆕 A implementar
```

**O Que Precisamos Implementar:**
```solidity
// Descoberta de posições Uniswap
function discoverUniswapPositions(address user)
    returns (uint256[] memory v3PositionIds, address[] memory v4Positions)

// Ver fees não reclamadas
function getUniswapFees(uint256[] v3Positions, address[] v4Positions)
    returns (uint256[] memory fees)

// Batch claim
function batchClaimUniswapFees(uint256[] v3Positions, address[] v4Positions)
```

---

## 🔍 Sistema de Descoberta de Tokens

### Arquitetura de Descoberta

```typescript
interface TokenDiscoveryService {
  // Descoberta unificada
  discoverAllUserTokens(userAddress: string): Promise<UnifiedTokenData>

  // Por protocolo
  discoverClankerTokens(userAddress: string): Promise<ClankerToken[]>
  discoverZoraTokens(userAddress: string): Promise<ZoraToken[]>
  discoverFlaunchTokens(userAddress: string): Promise<FlaunchToken[]>
  discoverMintClubTokens(userAddress: string): Promise<MintClubToken[]>

  // Descoberta de LP positions
  discoverLPPositions(userAddress: string): Promise<LPPosition[]>
}

interface UnifiedTokenData {
  tokens: Token[]
  lpPositions: LPPosition[]
  totalUnclaimedRewards: BigNumber
  protocols: {
    clanker: ClankerData
    zora: ZoraData
    flaunch: FlaunchData
    mintClub: MintClubData
    aerodrome: AerodromeData
    uniswap: UniswapData
  }
}
```

### Métodos de Descoberta

#### 1. **Event Listening (Mais Confiável)**

```typescript
// Indexar eventos de criação de tokens
const events = {
  clanker: {
    v4: 'TokenDeployed(address indexed creator, address indexed token)',
    v3: 'NewToken(address indexed token, address indexed creator)'
  },
  zora: {
    created: 'TokenCreated(address indexed creator, address indexed token)',
    minted: 'Minted(address indexed token, uint256 amount)'
  },
  flaunch: {
    launched: 'TokenLaunched(address indexed creator, address indexed token, uint256 nftId)',
    feesClaimed: 'FeesClaimed(address indexed token, uint256 amount)'
  }
}

// Usar The Graph ou Goldsky para indexação
const query = gql`
  query UserTokens($userAddress: String!) {
    clankerTokens(where: { creator: $userAddress }) {
      id
      token
      version
      createdAt
      feesClaimed
    }
    zoraTokens(where: { creator: $userAddress }) {
      id
      token
      totalSupply
      creatorFees
    }
    flaunchTokens(where: { creator: $userAddress }) {
      id
      token
      nftId
      fees
    }
  }
`
```

#### 2. **Contract Scanning (Backup)**

```typescript
// Scan de contratos factory
async function scanFactoryContracts(userAddress: string) {
  const factories = [
    { protocol: 'clanker', address: '0xE85A59c628F7d27878ACeB4bf3b35733630083a9' },
    // ... outros factories
  ]

  const results = await Promise.all(
    factories.map(factory =>
      scanFactory(factory.address, userAddress)
    )
  )

  return results.flat()
}

// Scan via RPC calls
async function scanFactory(factoryAddress: string, creator: string) {
  const factory = new Contract(factoryAddress, FACTORY_ABI, provider)

  // Método 1: Se o factory tem getter
  try {
    return await factory.getTokensByCreator(creator)
  } catch {}

  // Método 2: Scan de eventos
  const filter = factory.filters.TokenCreated(creator)
  const events = await factory.queryFilter(filter, 0, 'latest')

  return events.map(e => e.args.token)
}
```

#### 3. **API Integration (Mais Rápido)**

```typescript
// Usar APIs dos protocolos
const apiEndpoints = {
  clanker: 'https://api.clanker.world/tokens?creator=',
  zora: 'https://api.zora.co/tokens?creator=',
  // ... outros
}

async function fetchFromAPIs(userAddress: string) {
  const results = await Promise.all(
    Object.entries(apiEndpoints).map(async ([protocol, baseUrl]) => {
      try {
        const response = await fetch(`${baseUrl}${userAddress}`)
        const data = await response.json()
        return { protocol, tokens: data.tokens }
      } catch (error) {
        console.error(`Failed to fetch ${protocol}:`, error)
        return { protocol, tokens: [] }
      }
    })
  )

  return results.reduce((acc, { protocol, tokens }) => {
    acc[protocol] = tokens
    return acc
  }, {})
}
```

#### 4. **Multi-Strategy Approach (RECOMENDADO)**

```typescript
async function discoverAllTokens(userAddress: string): Promise<UnifiedTokenData> {
  // Usar múltiplas estratégias em paralelo para máxima confiabilidade
  const [apiResults, graphResults, scanResults] = await Promise.all([
    fetchFromAPIs(userAddress).catch(() => ({})),
    fetchFromTheGraph(userAddress).catch(() => ({})),
    scanFactoryContracts(userAddress).catch(() => ({}))
  ])

  // Merge e deduplicação
  return mergeAndDeduplicate(apiResults, graphResults, scanResults)
}

function mergeAndDeduplicate(...sources: any[]) {
  const tokenMap = new Map<string, Token>()

  sources.forEach(source => {
    Object.values(source).flat().forEach((token: any) => {
      if (!tokenMap.has(token.address)) {
        tokenMap.set(token.address, normalizeToken(token))
      }
    })
  })

  return Array.from(tokenMap.values())
}
```

---

## 💎 UX Suprema - Design System

### Princípios de UX

```yaml
1. Zero Configuração:
   - Cole seu endereço → Veja tudo instantaneamente

2. Transparência Total:
   - Veja EXATAMENTE o que vai ser claimed
   - Gas estimates em tempo real
   - Breakdown por protocolo

3. One-Click Everything:
   - Um botão para claim tudo
   - Customizações avançadas disponíveis mas não obrigatórias

4. Informação Antecipada:
   - Não descobrir problemas no meio do processo
   - Validações antes de enviar transação

5. Performance Suprema:
   - Load < 2 segundos
   - Atualizações em tempo real
   - Otimistic UI updates
```

### Interface Principal

```
┌─────────────────────────────────────────────────────────────┐
│  🎯 Universal Claim Dashboard                        [Wallet]│
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Seu Endereço: 0x1234...5678            [Auto-detected ✓]   │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  💰 Total Não Reclamado                               │  │
│  │                                                        │  │
│  │  $1,234.56 USD                                        │  │
│  │  ≈ 0.342 ETH + 1,250 tokens                          │  │
│  │                                                        │  │
│  │  [🚀 Claim Tudo (Gas: ~$0.85)]                       │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  📊 Breakdown por Protocolo                                  │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Clanker (5 tokens)                      $543.21  ▼│    │
│  ├─────────────────────────────────────────────────────┤    │
│  │ • DEGEN ($DEGEN)                    $234.50         │    │
│  │   v4.0 • 1,234 tokens                              │    │
│  │                                                      │    │
│  │ • AI Bot ($AIBOT)                   $156.80         │    │
│  │   v4.0 • 890 tokens                                │    │
│  │                                                      │    │
│  │ • Moon Token ($MOON)                $89.45          │    │
│  │   v3.1 • 456 tokens                                │    │
│  │                                                      │    │
│  │ + 2 mais...                                         │    │
│  │                                                      │    │
│  │ [Claim Clanker (Gas: ~$0.32)]                      │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Zora (3 tokens)                         $456.12  ▼│    │
│  ├─────────────────────────────────────────────────────┤    │
│  │ • Creator Coin ($CREATE)            $234.50         │    │
│  │   Creator fees • 2,340 tokens                      │    │
│  │                                                      │    │
│  │ • Art Token ($ART)                  $156.80         │    │
│  │   Creator fees • 1,890 tokens                      │    │
│  │                                                      │    │
│  │ + 1 mais...                                         │    │
│  │                                                      │    │
│  │ [Claim Zora (Gas: ~$0.28)]                         │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Flaunch (2 tokens)                      $235.23  ▼│    │
│  ├─────────────────────────────────────────────────────┤    │
│  │ • Meme Lord ($MEME)                 $156.80         │    │
│  │   Dev fees • NFT #1234 • 🔥 Buyback ready         │    │
│  │                                                      │    │
│  │ • Pump It ($PUMP)                   $78.43          │    │
│  │   Dev fees • NFT #5678                             │    │
│  │                                                      │    │
│  │ [Claim + Buyback (Gas: ~$0.45)]                    │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Features da UI

#### 1. **Smart Refresh**
```typescript
// Auto-refresh inteligente
- Ao conectar wallet: Refresh imediato
- Após transação: Refresh após confirmação
- Polling: A cada 30s se tab ativa
- WebSocket: Updates em tempo real quando disponível
```

#### 2. **Gas Optimization UI**
```typescript
// Mostrar opções de otimização
┌─────────────────────────────────────┐
│ ⚙️ Otimizar Gas                     │
├─────────────────────────────────────┤
│ ○ Padrão (~$0.85)                   │
│   Claim tudo em 1 transação         │
│                                      │
│ ◉ Otimizado (~$0.65) ← Recomendado  │
│   Apenas tokens com > $10           │
│   Economiza: $0.20                  │
│                                      │
│ ○ Custom                            │
│   Você escolhe o que claimar        │
└─────────────────────────────────────┘
```

#### 3. **Analytics Dashboard**
```typescript
┌─────────────────────────────────────────────┐
│ 📊 Suas Estatísticas                        │
├─────────────────────────────────────────────┤
│                                              │
│ Total Claimed (All-time):    $12,345.67     │
│ Total Gas Saved:             $234.56        │
│ Tokens Created:              23             │
│ Protocolos Usados:           4              │
│                                              │
│ ─────────────────────────────────────────   │
│                                              │
│ Distribuição por Protocolo:                 │
│                                              │
│ Clanker    ████████████░░░░ 60% ($7,407)   │
│ Zora       ██████░░░░░░░░░░ 25% ($3,086)   │
│ Flaunch    ███░░░░░░░░░░░░░ 10% ($1,235)   │
│ Mint Club  ██░░░░░░░░░░░░░░  5% ($617)     │
│                                              │
│ ─────────────────────────────────────────   │
│                                              │
│ Top 3 Tokens (por revenue):                 │
│                                              │
│ 1. $DEGEN     $2,345.67 • Clanker v4       │
│ 2. $CREATE    $1,890.45 • Zora             │
│ 3. $MEME      $1,234.56 • Flaunch          │
│                                              │
└─────────────────────────────────────────────┘
```

#### 4. **Transaction Preview**
```typescript
// Antes de enviar transação
┌───────────────────────────────────────┐
│ 🔍 Preview de Transação               │
├───────────────────────────────────────┤
│                                        │
│ Você vai receber:                     │
│ • 1,234 $DEGEN                        │
│ • 890 $AIBOT                          │
│ • 456 $MOON                           │
│ • 2,340 $CREATE                       │
│ • 1,890 $ART                          │
│ • 156 $MEME (+ buyback trigger)       │
│ • 78 $PUMP                            │
│                                        │
│ Total estimado: $1,234.56             │
│                                        │
│ ─────────────────────────────────────  │
│                                        │
│ Gas estimado: ~$0.85                  │
│ (0.0003 ETH @ 15 gwei)                │
│                                        │
│ Contratos que vão ser chamados: 3     │
│ • ClankerUniversalBatchClaim          │
│ • ZoraBatchClaim                      │
│ • FlaunchBatchClaim                   │
│                                        │
│ [Confirmar]  [Cancelar]               │
└───────────────────────────────────────┘
```

#### 5. **Error Handling UX**
```typescript
// Tratamento de erros friendly
┌──────────────────────────────────────────┐
│ ⚠️ Alguns Claims Falharam                │
├──────────────────────────────────────────┤
│                                           │
│ ✅ Clanker: 4/5 tokens claimed           │
│ ✅ Zora: 3/3 tokens claimed              │
│ ❌ Flaunch: 0/2 tokens claimed           │
│                                           │
│ Detalhes do erro:                        │
│ "Insufficient fees accumulated"          │
│                                           │
│ Você ainda recebeu: $1,000 em tokens     │
│                                           │
│ O que fazer:                             │
│ • Tokens Flaunch precisam acumular mais  │
│   fees (mínimo: 0.1 ETH)                 │
│ • Tente novamente em alguns dias         │
│                                           │
│ [Ver Tokens Claimed]  [Tentar Novamente] │
└──────────────────────────────────────────┘
```

---

## 🏗️ Arquitetura Técnica

### Stack Recomendado

```yaml
Frontend:
  Framework: Next.js 14+ (App Router)
  UI: Tailwind + shadcn/ui
  Web3: Wagmi v2 + Viem
  State: Zustand + React Query
  Charts: Recharts
  Notifications: Sonner

Backend/Indexing:
  Indexer: The Graph (Subgraph Studio)
  Alternativa: Goldsky
  Cache: Redis
  Database: PostgreSQL (para analytics)
  API: tRPC ou REST

Smart Contracts:
  Language: Solidity 0.8.28
  Framework: Foundry
  Testing: Forge + Hardhat
  Gas Optimization: Assembly quando necessário

Infraestrutura:
  Hosting: Vercel
  RPC: Alchemy ou QuickNode
  IPFS: Pinata (para metadata)
  Monitoring: Sentry + PostHog
```

### Smart Contract Architecture

```solidity
// Contrato principal unificado
contract UniversalClaimHub {
    // Batch claim de múltiplos protocolos
    function batchClaimMultiProtocol(
        ClaimData[] calldata claims
    ) external returns (ClaimResult[] memory results);

    // Estruturas
    struct ClaimData {
        Protocol protocol;
        address[] tokens;
        bytes extraData; // Dados específicos do protocolo
    }

    struct ClaimResult {
        Protocol protocol;
        address token;
        uint256 amount;
        bool success;
        string errorMessage;
    }

    enum Protocol {
        CLANKER_V4,
        CLANKER_V31,
        ZORA,
        FLAUNCH,
        MINT_CLUB,
        AERODROME,
        UNISWAP_V3,
        UNISWAP_V4
    }
}

// Módulos específicos por protocolo
contract ClankerClaimModule {
    function batchClaim(address[] calldata tokens, ClankerVersion[] versions)
        external returns (uint256[] memory amounts);
}

contract ZoraClaimModule {
    function batchClaim(address[] calldata tokens)
        external returns (uint256[] memory amounts);
}

contract FlaunchClaimModule {
    function batchClaim(address[] calldata tokens, bool triggerBuybacks)
        external returns (uint256[] memory amounts);
}

// ... outros módulos
```

### Diagrama de Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                     FRONTEND (Next.js)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  Dashboard   │  │  Analytics   │  │  Settings    │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                   API LAYER (tRPC)                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  Discovery   │  │  Rewards     │  │  Analytics   │ │
│  │  Service     │  │  Service     │  │  Service     │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└────────────┬──────────────┬─────────────┬──────────────┘
             │              │             │
             ▼              ▼             ▼
┌──────────────┐  ┌──────────────┐  ┌─────────────────┐
│  The Graph   │  │  Base RPC    │  │  PostgreSQL     │
│  (Indexer)   │  │  (Alchemy)   │  │  (Analytics DB) │
└──────────────┘  └──────────────┘  └─────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│              SMART CONTRACTS (Base Network)              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  Universal   │  │  Clanker     │  │  Zora        │ │
│  │  Claim Hub   │  │  Module      │  │  Module      │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  Flaunch     │  │  Mint Club   │  │  Uniswap     │ │
│  │  Module      │  │  Module      │  │  Module      │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## 📊 Roadmap de Implementação

### Fase 1: Foundation (Semanas 1-2)

```yaml
Objetivos:
  - Setup do projeto
  - Arquitetura base
  - Clanker (já existente) como baseline

Tasks:
  ✅ Setup Next.js + Wagmi + Tailwind
  ✅ Deploy contratos Clanker existentes
  ✅ UI básica funcionando
  ✅ Discovery básica (Clanker apenas)
  ✅ Batch claim funcionando
```

### Fase 2: Multi-Protocol Core (Semanas 3-4)

```yaml
Objetivos:
  - Adicionar Zora e Flaunch
  - Sistema de discovery multi-protocolo
  - UniversalClaimHub v1

Tasks:
  □ Smart contracts:
    □ ZoraClaimModule
    □ FlaunchClaimModule
    □ UniversalClaimHub (integração)
  □ Frontend:
    □ UI multi-protocolo
    □ Discovery service unificado
    □ Analytics básico
  □ The Graph:
    □ Subgraph para Zora
    □ Subgraph para Flaunch
    □ Query unificada
```

### Fase 3: UX Enhancement (Semanas 5-6)

```yaml
Objetivos:
  - UX suprema
  - Performance optimization
  - Analytics completo

Tasks:
  □ UI/UX:
    □ Transaction preview
    □ Gas optimization UI
    □ Error handling melhorado
    □ Loading states polidos
  □ Features:
    □ Auto-refresh inteligente
    □ Optimistic updates
    □ Analytics dashboard
    □ Export de dados
```

### Fase 4: Expansion (Semanas 7-8)

```yaml
Objetivos:
  - Adicionar protocolos restantes
  - LP positions support
  - Revenue features

Tasks:
  □ Protocolos:
    □ Mint Club integration
    □ Aerodrome LP claims
    □ Uniswap V3/V4 positions
  □ Features avançadas:
    □ Whitelist system
    □ Referral program
    □ Gamification (níveis)
```

### Fase 5: Launch (Semanas 9-10)

```yaml
Objetivos:
  - Beta testing
  - Auditing
  - Public launch

Tasks:
  □ Quality:
    □ Smart contract audit
    □ Security review
    □ Load testing
  □ Marketing:
    □ Content preparado
    □ Community building
    □ Partnership outreach
  □ Launch:
    □ Beta privado (100 users)
    □ Feedback iteration
    □ Public launch
```

---

## 💰 Modelo de Monetização

### Opção 1: Freemium (RECOMENDADO)

```yaml
Free Tier:
  - Até 10 claims/mês
  - Todos os protocolos
  - Analytics básico
  - Sem priority support

Pro Tier ($9.99/mês ou 0.5% fee):
  - Claims ilimitados
  - Analytics avançado
  - Priority support
  - Gas optimization AI
  - Custom alerts
  - API access

Enterprise:
  - Custom pricing
  - Dedicated support
  - Custom integrations
  - White label option
```

### Opção 2: Fee-Based (Como Clanker Pro)

```yaml
Estrutura:
  - 0.5% taxa em todos os claims
  - Desconto por volume (gamification)
  - Whitelist para VIPs
  - Referral: 20% commission

Níveis:
  - Nível 0-2: 0.5% fee
  - Nível 3-5: 0.4% fee
  - Nível 6-8: 0.3% fee
  - Nível 9-10: 0.25% fee
```

### Opção 3: Hybrid (MAIS SUSTENTÁVEL)

```yaml
Modelo:
  - Free tier generoso
  - Fee opcional de 0.3% para features premium
  - Revenue share com protocolos parceiros
  - NFT de membros (lifetime access)

Revenue Streams:
  1. Platform fees: 0.3% dos claims Pro
  2. Subscription: $9.99/mês Pro users
  3. Partnership deals: Rev share com Zora, Flaunch, etc
  4. NFT sales: Lifetime membership NFTs
  5. API access: Para agregadores/dashboards
```

---

## 🎯 Métricas de Sucesso

### North Star Metric
```
Total Value Unlocked (TVU) para usuários
= Soma de todos os rewards claimed através da plataforma
```

### KPIs Primários

```yaml
Adoção:
  - DAU/MAU
  - Total users
  - Protocolos por user

Engajamento:
  - Claims por user
  - Return rate (D7, D30)
  - Time in app

Revenue:
  - MRR/ARR
  - ARPU
  - LTV:CAC ratio

Value:
  - Total Value Unlocked
  - Gas saved
  - Tokens discovered

Viralidade:
  - Referral rate
  - K-factor
  - Social shares
```

### Targets Ano 1

```
Mês 1-3 (Beta):
  Users: 500-1,000
  TVU: $50k-$100k
  MRR: $500-$1,000

Mês 4-6 (Growth):
  Users: 2,000-5,000
  TVU: $250k-$500k
  MRR: $2,000-$5,000

Mês 7-9 (Scale):
  Users: 5,000-15,000
  TVU: $500k-$1.5M
  MRR: $5,000-$15,000

Mês 10-12 (Established):
  Users: 15,000-50,000
  TVU: $1.5M-$5M
  MRR: $15,000-$50,000
```

---

## 🚀 Go-to-Market Strategy

### Target Audiences

#### 1. Token Creators (Primary)
```
Quem: Pessoas que criaram tokens em Clanker, Zora, Flaunch
Dor: Gerenciar rewards de múltiplos protocolos é complexo
Valor: Veja e claim tudo em um lugar
Aquisição:
  - Posts nos canais oficiais (Farcaster, Twitter)
  - Partnership com os protocolos
  - Content: "Token Creator's Guide to Maximizing Rewards"
```

#### 2. Traders/Holders (Secondary)
```
Quem: People que têm LP positions ou tokens
Dor: Esquecem de claimar fees
Valor: Descoberta automática + lembretes
Aquisição:
  - SEO: "How to claim Base LP fees"
  - Twitter: Showcase de savings
  - Referral incentives
```

#### 3. Developers (Tertiary)
```
Quem: Builders que querem integrar
Dor: Integrar múltiplos protocolos é trabalhoso
Valor: API unificada
Aquisição:
  - Dev documentation
  - Open source tools
  - Hackathons
```

### Lançamento

#### Week 1-2: Teaser Campaign
```
- Tweet thread: "The state of token claiming is broken"
- Farcaster posts sobre cada protocolo
- Sneak peeks da UI
- Waitlist signup
```

#### Week 3: Beta Launch
```
- 100 primeiros users (whitelist)
- Foco em feedback
- Iterate rápido
- Case studies
```

#### Week 4-6: Public Launch
```
- Announcement coordenado
- Partnership announcements (Zora, Flaunch, etc)
- Demo videos
- Twitter Spaces
- Product Hunt launch
```

#### Week 7+: Growth
```
- Content marketing
- Referral program
- Community building
- Feature drops semanais
```

---

## 📚 Recursos e Referências

### Contratos

```solidity
// Base Mainnet (Chain ID: 8453)

// Clanker
FEE_LOCKER_V4 = 0xF3622742b1E446D92e45E22923Ef11C2fcD55D68
FACTORY_V4 = 0xE85A59c628F7d27878ACeB4bf3b35733630083a9

// Zora
ZORA_TOKEN = 0x1111111111166b7fe7bd91427724b487980afc69

// Flaunch
FLAY_TOKEN = 0xf1a7000000950c7ad8aff13118bb7ab561a448ee

// Uniswap
V3_POSITION_MANAGER = 0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1
V4_POOL_MANAGER = 0x7Da1D65F8B249183667cdE74C5CBD46dD38AA829

// WETH
WETH = 0x4200000000000000000000000000000000000006
```

### APIs e Docs

```
Clanker:
  - API: https://api.clanker.world
  - Docs: https://clanker.gitbook.io/

Zora:
  - API: https://api.zora.co
  - Docs: https://docs.zora.co

Flaunch:
  - Website: https://flaunch.gg
  - Uniswap V4 Docs: https://docs.uniswap.org/contracts/v4/overview

Base:
  - RPC: https://mainnet.base.org
  - Explorer: https://basescan.org
  - Docs: https://docs.base.org
```

### Tools

```
Development:
  - Foundry: https://book.getfoundry.sh/
  - Wagmi: https://wagmi.sh/
  - Viem: https://viem.sh/

Indexing:
  - The Graph: https://thegraph.com/
  - Goldsky: https://goldsky.com/

Hosting:
  - Vercel: https://vercel.com/
  - Railway: https://railway.app/
```

---

## ✅ Checklist de Implementação

### Smart Contracts
- [ ] UniversalClaimHub base contract
- [ ] ZoraClaimModule
- [ ] FlaunchClaimModule
- [ ] MintClubClaimModule
- [ ] AerodromeClaimModule
- [ ] UniswapClaimModule
- [ ] Tests completos (>90% coverage)
- [ ] Gas optimization
- [ ] Audit externo

### Backend/Indexing
- [ ] The Graph subgraphs
  - [ ] Clanker subgraph
  - [ ] Zora subgraph
  - [ ] Flaunch subgraph
  - [ ] Outros protocolos
- [ ] API layer (tRPC)
- [ ] PostgreSQL setup
- [ ] Redis caching
- [ ] Rate limiting

### Frontend
- [ ] Next.js setup
- [ ] Wagmi integration
- [ ] Dashboard UI
- [ ] Analytics page
- [ ] Settings page
- [ ] Transaction preview
- [ ] Error handling
- [ ] Loading states
- [ ] Mobile responsive
- [ ] Dark mode

### Features
- [ ] Token discovery
- [ ] Multi-protocol claiming
- [ ] Gas optimization
- [ ] Analytics dashboard
- [ ] Export functionality
- [ ] Notifications
- [ ] Referral system
- [ ] Gamification

### Testing
- [ ] Unit tests
- [ ] Integration tests
- [ ] E2E tests
- [ ] Load testing
- [ ] Security testing

### Documentation
- [ ] User guides
- [ ] Developer docs
- [ ] API documentation
- [ ] Video tutorials
- [ ] FAQ

### Marketing
- [ ] Landing page
- [ ] Content calendar
- [ ] Social media assets
- [ ] Partnership outreach
- [ ] Community setup

### Launch
- [ ] Beta testing (100 users)
- [ ] Feedback collection
- [ ] Bug fixes
- [ ] Public announcement
- [ ] Monitoring setup

---

## 💡 Ideias Futuras

### V2 Features
```
- Multi-chain support (Ethereum, Arbitrum, Optimism)
- Auto-compound functionality
- Tax reporting integration
- Mobile app (React Native)
- Telegram/Discord bots
- Portfolio tracking
- Token swap integration
- Governance participation tracking
```

### Partnerships
```
- Integração com wallets (Rainbow, Coinbase Wallet)
- Partnership com agregadores (DeBank, Zapper)
- Integração com tax tools (Koinly, CoinTracker)
- Listing em marketplaces (DappRadar, etc)
```

### DAO/Governance
```
- Token de governança
- Community-driven development
- Protocol-owned liquidity
- Treasury management
- Grants program
```

---

## 🎯 Conclusão

Esta extensão transforma o plano original focado em Clanker em uma **plataforma universal de claim de rewards** que:

✅ Suporta 6+ protocolos de token launch na Base
✅ Descobre automaticamente todos os tokens de um usuário
✅ Oferece UX suprema com one-click claiming
✅ Economiza 80%+ em gas fees
✅ Gera revenue sustentável
✅ Escala para todo o ecossistema Base

**Next Steps:**
1. Review deste documento com a equipe
2. Priorizar protocolos para Fase 2
3. Setup do projeto base
4. Começar implementação modular

**Let's build! 🚀**

---

*Documento criado em: 2025-11-13*
*Versão: 1.0*
*Status: Draft para Review*
