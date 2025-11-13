# 🔍 Sistema de Descoberta de Tokens - Arquitetura Completa

## 📋 Visão Geral

Sistema automático para descobrir TODOS os tokens que um usuário criou/possui em múltiplos protocolos da Base Network, usando apenas seu endereço.

## 🎯 Problema a Resolver

```
Usuário tem:
- 5 tokens no Clanker v4
- 3 tokens no Zora
- 2 tokens no Flaunch
- LP positions no Aerodrome
- Posições Uniswap V3/V4

Mas ele não lembra quais são! ❌

Nossa solução: Cole seu endereço → Veja tudo ✅
```

---

## 🏗️ Arquitetura Multi-Layer

### Layer 1: The Graph (Indexador On-Chain)
**Velocidade:** ⚡⚡⚡ Rápido
**Confiabilidade:** ⭐⭐⭐⭐⭐ Alta
**Custo:** 💰 Médio

```graphql
# Subgraph Schema
type Token @entity {
  id: ID!
  address: Bytes!
  creator: Bytes!
  protocol: Protocol!
  createdAt: BigInt!
  totalSupply: BigInt!
  feesClaimed: BigInt!
  feesUnclaimed: BigInt!
  metadata: TokenMetadata
}

type Protocol @entity {
  id: ID!
  name: String!
  factory: Bytes!
  tokens: [Token!]! @derivedFrom(field: "protocol")
}

type User @entity {
  id: ID!
  address: Bytes!
  tokensCreated: [Token!]! @derivedFrom(field: "creator")
  totalFeesEarned: BigInt!
  claimsCount: Int!
}

type ClaimEvent @entity {
  id: ID!
  user: User!
  token: Token!
  amount: BigInt!
  timestamp: BigInt!
  txHash: Bytes!
}
```

### Layer 2: Protocol APIs (Oficial)
**Velocidade:** ⚡⚡ Médio
**Confiabilidade:** ⭐⭐⭐⭐ Alta
**Custo:** 💰 Baixo/Grátis

```typescript
// Integração com APIs oficiais
const protocolAPIs = {
  clanker: {
    baseUrl: 'https://api.clanker.world',
    endpoints: {
      userTokens: '/tokens?creator={address}',
      tokenInfo: '/tokens/{tokenAddress}',
      rewards: '/rewards/{address}'
    }
  },
  zora: {
    baseUrl: 'https://api.zora.co',
    endpoints: {
      creatorTokens: '/v1/tokens?creator={address}',
      tokenMetadata: '/v1/tokens/{tokenAddress}'
    }
  }
}
```

### Layer 3: RPC Scanning (Fallback)
**Velocidade:** ⚡ Lento
**Confiabilidade:** ⭐⭐⭐ Média
**Custo:** 💰💰 Alto (muitas calls)

```typescript
// Scan de eventos via RPC
async function scanProtocolEvents(
  userAddress: string,
  fromBlock: number
): Promise<Token[]> {
  // Scan factory contracts por eventos de criação
}
```

### Layer 4: Cache + Database
**Velocidade:** ⚡⚡⚡⚡ Muito Rápido
**Confiabilidade:** ⭐⭐⭐⭐⭐ Alta
**Custo:** 💰 Baixo

```typescript
// Cache Redis + PostgreSQL
interface CachedUserData {
  address: string
  tokens: Token[]
  lastUpdated: Date
  ttl: number // Time to live
}
```

---

## 📊 Implementação Completa

### 1. Service Principal

```typescript
// services/TokenDiscoveryService.ts

import { GraphQLClient } from 'graphql-request'
import { Redis } from 'ioredis'
import { PrismaClient } from '@prisma/client'

export class TokenDiscoveryService {
  private graphClient: GraphQLClient
  private redis: Redis
  private prisma: PrismaClient
  private protocolAPIs: Map<string, ProtocolAPI>

  constructor() {
    this.graphClient = new GraphQLClient(process.env.SUBGRAPH_URL!)
    this.redis = new Redis(process.env.REDIS_URL!)
    this.prisma = new PrismaClient()
    this.protocolAPIs = this.initializeAPIs()
  }

  /**
   * Método principal: Descobrir todos os tokens de um usuário
   */
  async discoverAllTokens(
    userAddress: string,
    options: DiscoveryOptions = {}
  ): Promise<UnifiedTokenData> {
    const startTime = Date.now()

    // 1. Verificar cache
    const cached = await this.checkCache(userAddress)
    if (cached && !options.forceRefresh) {
      return cached
    }

    // 2. Executar discovery em paralelo (todas as estratégias)
    const [
      graphResults,
      apiResults,
      scanResults,
      dbResults
    ] = await Promise.allSettled([
      this.discoverViaTheGraph(userAddress),
      this.discoverViaAPIs(userAddress),
      this.discoverViaRPCScan(userAddress),
      this.discoverViaDatabase(userAddress)
    ])

    // 3. Merge e deduplicate
    const mergedData = this.mergeResults([
      graphResults,
      apiResults,
      scanResults,
      dbResults
    ])

    // 4. Enrich com rewards data
    const enrichedData = await this.enrichWithRewards(mergedData)

    // 5. Salvar no cache e database
    await this.saveToCache(userAddress, enrichedData)
    await this.saveToDatabase(userAddress, enrichedData)

    const duration = Date.now() - startTime
    console.log(`Discovery completed in ${duration}ms`)

    return enrichedData
  }

  /**
   * Strategy 1: The Graph
   */
  private async discoverViaTheGraph(
    userAddress: string
  ): Promise<Partial<UnifiedTokenData>> {
    const query = `
      query UserTokens($address: Bytes!) {
        user(id: $address) {
          id
          tokensCreated {
            id
            address
            protocol {
              name
            }
            createdAt
            totalSupply
            feesClaimed
            feesUnclaimed
            metadata {
              name
              symbol
              decimals
            }
          }
          totalFeesEarned
          claimsCount
        }
      }
    `

    try {
      const data = await this.graphClient.request(query, {
        address: userAddress.toLowerCase()
      })

      return this.transformGraphData(data)
    } catch (error) {
      console.error('The Graph error:', error)
      return { tokens: [] }
    }
  }

  /**
   * Strategy 2: Protocol APIs
   */
  private async discoverViaAPIs(
    userAddress: string
  ): Promise<Partial<UnifiedTokenData>> {
    const results = await Promise.allSettled(
      Array.from(this.protocolAPIs.entries()).map(
        async ([protocolName, api]) => {
          try {
            const tokens = await api.getUserTokens(userAddress)
            return { protocol: protocolName, tokens }
          } catch (error) {
            console.error(`${protocolName} API error:`, error)
            return { protocol: protocolName, tokens: [] }
          }
        }
      )
    )

    return this.transformAPIResults(results)
  }

  /**
   * Strategy 3: RPC Scanning (fallback)
   */
  private async discoverViaRPCScan(
    userAddress: string
  ): Promise<Partial<UnifiedTokenData>> {
    // Só usar se outras estratégias falharem
    const factories = [
      {
        protocol: 'clanker',
        address: '0xE85A59c628F7d27878ACeB4bf3b35733630083a9',
        event: 'TokenDeployed(address,address,uint256)'
      },
      // ... outros factories
    ]

    const scanner = new RPCScanner()
    const tokens = await scanner.scanFactories(userAddress, factories)

    return { tokens }
  }

  /**
   * Strategy 4: Database lookup
   */
  private async discoverViaDatabase(
    userAddress: string
  ): Promise<Partial<UnifiedTokenData>> {
    const dbTokens = await this.prisma.token.findMany({
      where: {
        creator: userAddress.toLowerCase()
      },
      include: {
        protocol: true,
        rewards: true
      }
    })

    return this.transformDBData(dbTokens)
  }

  /**
   * Merge e deduplicate results
   */
  private mergeResults(
    results: PromiseSettledResult<Partial<UnifiedTokenData>>[]
  ): UnifiedTokenData {
    const tokenMap = new Map<string, Token>()
    const protocolData: Record<string, any> = {}

    results.forEach(result => {
      if (result.status === 'fulfilled') {
        const data = result.value

        // Merge tokens
        data.tokens?.forEach(token => {
          const key = token.address.toLowerCase()

          if (!tokenMap.has(key)) {
            tokenMap.set(key, token)
          } else {
            // Merge dados se já existir
            const existing = tokenMap.get(key)!
            tokenMap.set(key, this.mergeTokenData(existing, token))
          }
        })

        // Merge protocol-specific data
        if (data.protocols) {
          Object.entries(data.protocols).forEach(([protocol, pdata]) => {
            protocolData[protocol] = {
              ...protocolData[protocol],
              ...pdata
            }
          })
        }
      }
    })

    const tokens = Array.from(tokenMap.values())

    return {
      tokens,
      lpPositions: [], // TODO: Implementar
      totalUnclaimedRewards: this.calculateTotalRewards(tokens),
      protocols: protocolData,
      metadata: {
        discoveredAt: new Date(),
        source: 'multi-strategy',
        tokensCount: tokens.length
      }
    }
  }

  /**
   * Enrich com rewards data em tempo real
   */
  private async enrichWithRewards(
    data: UnifiedTokenData
  ): Promise<UnifiedTokenData> {
    // Buscar rewards não reclamadas para cada token
    const enrichedTokens = await Promise.all(
      data.tokens.map(async token => {
        try {
          const rewards = await this.fetchTokenRewards(token)
          return { ...token, unclaimedRewards: rewards }
        } catch (error) {
          console.error(`Error fetching rewards for ${token.address}:`, error)
          return token
        }
      })
    )

    return {
      ...data,
      tokens: enrichedTokens,
      totalUnclaimedRewards: enrichedTokens.reduce(
        (sum, t) => sum + (t.unclaimedRewards || 0),
        0
      )
    }
  }

  /**
   * Cache management
   */
  private async checkCache(
    userAddress: string
  ): Promise<UnifiedTokenData | null> {
    const key = `tokens:${userAddress.toLowerCase()}`
    const cached = await this.redis.get(key)

    if (cached) {
      const data = JSON.parse(cached)
      const age = Date.now() - new Date(data.metadata.discoveredAt).getTime()

      // Cache válido por 5 minutos
      if (age < 5 * 60 * 1000) {
        return data
      }
    }

    return null
  }

  private async saveToCache(
    userAddress: string,
    data: UnifiedTokenData
  ): Promise<void> {
    const key = `tokens:${userAddress.toLowerCase()}`
    await this.redis.setex(
      key,
      300, // 5 minutos
      JSON.stringify(data)
    )
  }

  private async saveToDatabase(
    userAddress: string,
    data: UnifiedTokenData
  ): Promise<void> {
    // Salvar ou atualizar no PostgreSQL
    await this.prisma.userTokenSnapshot.upsert({
      where: { userAddress: userAddress.toLowerCase() },
      update: {
        tokens: data.tokens as any,
        totalUnclaimedRewards: data.totalUnclaimedRewards,
        lastUpdated: new Date()
      },
      create: {
        userAddress: userAddress.toLowerCase(),
        tokens: data.tokens as any,
        totalUnclaimedRewards: data.totalUnclaimedRewards
      }
    })
  }
}
```

---

### 2. Protocol API Adapters

```typescript
// services/adapters/ClankerAdapter.ts

export class ClankerAPIAdapter implements ProtocolAPI {
  private baseUrl = 'https://api.clanker.world'

  async getUserTokens(userAddress: string): Promise<Token[]> {
    const response = await fetch(
      `${this.baseUrl}/tokens?creator=${userAddress}`
    )

    if (!response.ok) {
      throw new Error(`Clanker API error: ${response.statusText}`)
    }

    const data = await response.json()

    return data.tokens.map(this.transformToken)
  }

  async getTokenRewards(tokenAddress: string): Promise<number> {
    const response = await fetch(
      `${this.baseUrl}/rewards/${tokenAddress}`
    )

    const data = await response.json()
    return data.unclaimed || 0
  }

  private transformToken(apiToken: any): Token {
    return {
      address: apiToken.address,
      name: apiToken.name,
      symbol: apiToken.symbol,
      protocol: 'clanker',
      version: apiToken.version,
      creator: apiToken.creator,
      createdAt: new Date(apiToken.createdAt),
      totalSupply: BigInt(apiToken.totalSupply),
      metadata: {
        decimals: 18,
        logo: apiToken.logo,
        description: apiToken.description
      }
    }
  }
}

// services/adapters/ZoraAdapter.ts

export class ZoraAPIAdapter implements ProtocolAPI {
  private baseUrl = 'https://api.zora.co'

  async getUserTokens(userAddress: string): Promise<Token[]> {
    const response = await fetch(
      `${this.baseUrl}/v1/tokens?creator=${userAddress}&chain=base`
    )

    if (!response.ok) {
      throw new Error(`Zora API error: ${response.statusText}`)
    }

    const data = await response.json()

    return data.tokens.map(this.transformToken)
  }

  async getTokenRewards(tokenAddress: string): Promise<number> {
    // Zora rewards são 50% das trading fees
    // Buscar via contract call ou API
    return 0 // TODO: Implementar
  }

  private transformToken(apiToken: any): Token {
    return {
      address: apiToken.address,
      name: apiToken.name,
      symbol: apiToken.symbol,
      protocol: 'zora',
      creator: apiToken.creator,
      createdAt: new Date(apiToken.created_at),
      totalSupply: BigInt(apiToken.total_supply),
      metadata: {
        decimals: 18,
        logo: apiToken.media?.image?.url,
        description: apiToken.description
      }
    }
  }
}
```

---

### 3. RPC Scanner (Fallback)

```typescript
// services/RPCScanner.ts

import { createPublicClient, http, parseAbiItem } from 'viem'
import { base } from 'viem/chains'

export class RPCScanner {
  private client: ReturnType<typeof createPublicClient>

  constructor() {
    this.client = createPublicClient({
      chain: base,
      transport: http(process.env.BASE_RPC_URL)
    })
  }

  /**
   * Scan factory contracts por eventos de criação
   */
  async scanFactories(
    userAddress: string,
    factories: FactoryConfig[]
  ): Promise<Token[]> {
    const tokens: Token[] = []

    for (const factory of factories) {
      try {
        const factoryTokens = await this.scanFactory(
          userAddress,
          factory
        )
        tokens.push(...factoryTokens)
      } catch (error) {
        console.error(`Error scanning ${factory.protocol}:`, error)
      }
    }

    return tokens
  }

  private async scanFactory(
    userAddress: string,
    factory: FactoryConfig
  ): Promise<Token[]> {
    // Evento de criação de token
    const event = parseAbiItem(factory.event)

    // Buscar eventos do bloco inicial até atual
    const logs = await this.client.getLogs({
      address: factory.address as `0x${string}`,
      event,
      args: {
        creator: userAddress as `0x${string}`
      },
      fromBlock: factory.deployBlock || 0n,
      toBlock: 'latest'
    })

    // Transformar logs em tokens
    return logs.map(log => ({
      address: log.args.token as string,
      protocol: factory.protocol,
      creator: userAddress,
      createdAt: new Date(), // Buscar timestamp do block
      // ... outros campos
    }))
  }

  /**
   * Buscar metadata de um token via contract calls
   */
  async getTokenMetadata(tokenAddress: string): Promise<TokenMetadata> {
    const [name, symbol, decimals, totalSupply] = await Promise.all([
      this.client.readContract({
        address: tokenAddress as `0x${string}`,
        abi: ERC20_ABI,
        functionName: 'name'
      }),
      this.client.readContract({
        address: tokenAddress as `0x${string}`,
        abi: ERC20_ABI,
        functionName: 'symbol'
      }),
      this.client.readContract({
        address: tokenAddress as `0x${string}`,
        abi: ERC20_ABI,
        functionName: 'decimals'
      }),
      this.client.readContract({
        address: tokenAddress as `0x${string}`,
        abi: ERC20_ABI,
        functionName: 'totalSupply'
      })
    ])

    return {
      name: name as string,
      symbol: symbol as string,
      decimals: decimals as number,
      totalSupply: totalSupply as bigint
    }
  }
}
```

---

### 4. The Graph Subgraph

```yaml
# subgraph.yaml

specVersion: 0.0.5
schema:
  file: ./schema.graphql
dataSources:
  # Clanker v4
  - kind: ethereum
    name: ClankerV4Factory
    network: base
    source:
      address: "0xE85A59c628F7d27878ACeB4bf3b35733630083a9"
      abi: ClankerFactory
      startBlock: 10000000
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - Token
        - User
        - Protocol
      abis:
        - name: ClankerFactory
          file: ./abis/ClankerFactory.json
        - name: ERC20
          file: ./abis/ERC20.json
      eventHandlers:
        - event: TokenDeployed(indexed address,indexed address,uint256)
          handler: handleTokenDeployed
      file: ./src/clanker.ts

  # Zora
  - kind: ethereum
    name: ZoraFactory
    network: base
    source:
      address: "0x..." # Zora factory address
      abi: ZoraFactory
      startBlock: 12000000
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - Token
        - User
      abis:
        - name: ZoraFactory
          file: ./abis/ZoraFactory.json
      eventHandlers:
        - event: TokenCreated(indexed address,indexed address)
          handler: handleTokenCreated
      file: ./src/zora.ts

  # Flaunch
  - kind: ethereum
    name: FlaunchPlatform
    network: base
    source:
      address: "0x..." # Flaunch address
      abi: Flaunch
      startBlock: 13000000
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - Token
        - User
      abis:
        - name: Flaunch
          file: ./abis/Flaunch.json
      eventHandlers:
        - event: TokenLaunched(indexed address,indexed address,uint256)
          handler: handleTokenLaunched
      file: ./src/flaunch.ts
```

```typescript
// src/clanker.ts (Subgraph mapping)

import { TokenDeployed } from "../generated/ClankerV4Factory/ClankerFactory"
import { Token, User, Protocol } from "../generated/schema"
import { Address, BigInt } from "@graphprotocol/graph-ts"

export function handleTokenDeployed(event: TokenDeployed): void {
  // Carregar ou criar User
  let user = User.load(event.params.creator.toHex())
  if (!user) {
    user = new User(event.params.creator.toHex())
    user.address = event.params.creator
    user.totalFeesEarned = BigInt.fromI32(0)
    user.claimsCount = 0
    user.save()
  }

  // Carregar ou criar Protocol
  let protocol = Protocol.load("clanker-v4")
  if (!protocol) {
    protocol = new Protocol("clanker-v4")
    protocol.name = "Clanker v4"
    protocol.factory = Address.fromString("0xE85A59c628F7d27878ACeB4bf3b35733630083a9")
    protocol.save()
  }

  // Criar Token
  let token = new Token(event.params.token.toHex())
  token.address = event.params.token
  token.creator = event.params.creator
  token.protocol = protocol.id
  token.createdAt = event.block.timestamp
  token.totalSupply = BigInt.fromI32(0) // Buscar via call
  token.feesClaimed = BigInt.fromI32(0)
  token.feesUnclaimed = BigInt.fromI32(0)

  // Buscar metadata via contract call
  // let tokenContract = ERC20.bind(event.params.token)
  // token.name = tokenContract.try_name().value
  // token.symbol = tokenContract.try_symbol().value

  token.save()
}
```

---

### 5. Frontend Integration

```typescript
// hooks/useTokenDiscovery.ts

import { useQuery } from '@tanstack/react-query'
import { useAccount } from 'wagmi'

export function useTokenDiscovery() {
  const { address } = useAccount()

  return useQuery({
    queryKey: ['tokens', address],
    queryFn: async () => {
      if (!address) return null

      const response = await fetch(`/api/discover/${address}`)
      return response.json()
    },
    enabled: !!address,
    staleTime: 5 * 60 * 1000, // 5 minutos
    refetchOnWindowFocus: true
  })
}

// Componente
function TokenDashboard() {
  const { data: tokenData, isLoading, refetch } = useTokenDiscovery()

  if (isLoading) {
    return <LoadingSkeleton />
  }

  return (
    <div>
      <h1>Seus Tokens</h1>
      <p>Total descobertos: {tokenData?.tokens.length}</p>
      <p>Rewards não reclamados: ${tokenData?.totalUnclaimedRewards}</p>

      <button onClick={() => refetch()}>
        🔄 Atualizar
      </button>

      <TokenList tokens={tokenData?.tokens} />
    </div>
  )
}
```

---

## 📊 Performance Optimization

### 1. Caching Strategy

```typescript
// Multi-level cache
const cacheStrategy = {
  l1: 'Redis (5 min TTL)',      // Hot data
  l2: 'PostgreSQL (1 hour)',     // Warm data
  l3: 'The Graph (real-time)',   // Cold data
}

// Smart invalidation
async function invalidateCache(userAddress: string) {
  await redis.del(`tokens:${userAddress}`)
  // Trigger refresh in background
  backgroundRefresh(userAddress)
}
```

### 2. Pagination

```typescript
// Para usuários com muitos tokens
interface DiscoveryOptions {
  limit?: number
  offset?: number
  sortBy?: 'createdAt' | 'rewards' | 'value'
  protocols?: Protocol[]
}
```

### 3. Parallel Fetching

```typescript
// Buscar dados em paralelo
const [tokens, rewards, metadata] = await Promise.all([
  fetchTokens(),
  fetchRewards(),
  fetchMetadata()
])
```

### 4. Incremental Updates

```typescript
// Não buscar tudo sempre, apenas novos
async function incrementalDiscovery(
  userAddress: string,
  lastUpdate: Date
): Promise<Token[]> {
  // Apenas tokens criados após lastUpdate
  return discoverTokensSince(userAddress, lastUpdate)
}
```

---

## 📈 Monitoring & Analytics

### Metrics to Track

```typescript
interface DiscoveryMetrics {
  // Performance
  averageDiscoveryTime: number
  cacheHitRate: number
  apiErrorRate: number

  // Usage
  totalDiscoveries: number
  uniqueUsers: number
  averageTokensPerUser: number

  // Data quality
  graphDataAvailability: number
  apiDataAvailability: number
  dataMismatchRate: number
}
```

---

## ✅ Checklist

### Backend
- [ ] TokenDiscoveryService core
- [ ] Protocol adapters (Clanker, Zora, Flaunch)
- [ ] RPC scanner fallback
- [ ] The Graph subgraphs
- [ ] Redis caching
- [ ] PostgreSQL storage
- [ ] API endpoints

### Frontend
- [ ] useTokenDiscovery hook
- [ ] Dashboard UI
- [ ] Loading states
- [ ] Error handling
- [ ] Refresh functionality

### Testing
- [ ] Unit tests
- [ ] Integration tests
- [ ] Load testing
- [ ] Cache testing

### Documentation
- [ ] API documentation
- [ ] Integration guide
- [ ] Troubleshooting guide

---

## 🚀 Next Steps

1. Implementar The Graph subgraph para Clanker
2. Criar adapters para Zora e Flaunch APIs
3. Setup Redis + PostgreSQL
4. Implementar service de discovery
5. Criar frontend hooks
6. Testing completo

---

**Status:** 🚧 Pronto para Implementação
**Prioridade:** 🔥 Alta (Core Feature)
