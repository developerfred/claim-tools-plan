// frontend-config-example.ts
// Copiar este arquivo para o frontend como lib/contracts.ts

import { Address } from 'viem';

// ========== TYPES ==========

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

export interface ClaimRequest {
  protocol: Protocol;
  tokens: Address[];
  extraData: `0x${string}`;
}

export interface ClaimResult {
  protocol: Protocol;
  token: Address;
  amount: bigint;
  success: boolean;
  errorMessage: string;
}

// ========== CONTRACT ADDRESSES ==========

// TODO: Atualizar com endereços reais após deploy
export const CONTRACTS = {
  // Base Mainnet (Chain ID: 8453)
  8453: {
    UniversalClaimHub: '0x...' as Address, // TODO: Update after deploy
    ClankerModule: '0x...' as Address,
    ZoraModule: '0x...' as Address,
    FlaunchModule: '0x...' as Address,
  },
  // Base Sepolia (Chain ID: 84532)
  84532: {
    UniversalClaimHub: '0x...' as Address, // TODO: Update after deploy
    ClankerModule: '0x...' as Address,
    ZoraModule: '0x...' as Address,
    FlaunchModule: '0x...' as Address,
  }
} as const;

// Protocol addresses (já conhecidos)
export const PROTOCOL_ADDRESSES = {
  clanker: {
    feeLockerV4: '0xF3622742b1E446D92e45E22923Ef11C2fcD55D68' as Address,
    lpLockerV31: '0x33e2Eda238edcF470309b8c6D228986A1204c8f9' as Address,
    lpLockerV30: '0x5eC4f99F342038c67a312a166Ff56e6D70383D86' as Address,
    lpLockerV20: '0x618A9840691334eE8d24445a4AdA4284Bf42417D' as Address,
    factoryV4: '0xE85A59c628F7d27878ACeB4bf3b35733630083a9' as Address,
  },
  zora: {
    token: '0x1111111111166b7fe7bd91427724b487980afc69' as Address,
  },
  flaunch: {
    flay: '0xf1a7000000950c7ad8aff13118bb7ab561a448ee' as Address,
  },
  base: {
    weth: '0x4200000000000000000000000000000000000006' as Address,
  }
} as const;

// ========== HELPER FUNCTIONS ==========

/**
 * Get contract address for current chain
 */
export function getContractAddress(
  chainId: number,
  contractName: keyof typeof CONTRACTS[8453]
): Address | undefined {
  return CONTRACTS[chainId as keyof typeof CONTRACTS]?.[contractName];
}

/**
 * Encode extraData for Clanker module
 */
export function encodeClankerExtraData(
  tokenVersions: Array<{ token: Address; version: 0 | 1 | 2 | 3 }>
): `0x${string}` {
  // TODO: Implement ABI encoding
  // For now, return empty
  return '0x';
}

/**
 * Encode extraData for Flaunch module (buyback flag)
 */
export function encodeFlaunchExtraData(triggerBuyback: boolean): `0x${string}` {
  // TODO: Implement ABI encoding
  // For now, return empty
  return '0x';
}

/**
 * Build claim request for protocol
 */
export function buildClaimRequest(
  protocol: Protocol,
  tokens: Address[],
  extraData?: `0x${string}`
): ClaimRequest {
  return {
    protocol,
    tokens,
    extraData: extraData || '0x',
  };
}

// ========== RPC ENDPOINTS ==========

export const RPC_URLS = {
  base: {
    mainnet: 'https://mainnet.base.org',
    sepolia: 'https://sepolia.base.org',
  },
  alchemy: {
    base: `https://base-mainnet.g.alchemy.com/v2/${process.env.NEXT_PUBLIC_ALCHEMY_KEY}`,
    baseSepolia: `https://base-sepolia.g.alchemy.com/v2/${process.env.NEXT_PUBLIC_ALCHEMY_KEY}`,
  }
} as const;

// ========== BLOCK EXPLORERS ==========

export const BLOCK_EXPLORERS = {
  base: 'https://basescan.org',
  baseSepolia: 'https://sepolia.basescan.org',
} as const;

// ========== HELPER: Format transaction URL ==========

export function getTxUrl(txHash: string, chainId: number): string {
  const explorer = chainId === 8453 ? BLOCK_EXPLORERS.base : BLOCK_EXPLORERS.baseSepolia;
  return `${explorer}/tx/${txHash}`;
}

export function getAddressUrl(address: string, chainId: number): string {
  const explorer = chainId === 8453 ? BLOCK_EXPLORERS.base : BLOCK_EXPLORERS.baseSepolia;
  return `${explorer}/address/${address}`;
}

// ========== API ENDPOINTS ==========

export const API_ENDPOINTS = {
  clanker: 'https://api.clanker.world',
  zora: 'https://api.zora.co',
  // TODO: Add more as needed
} as const;

// ========== CONSTANTS ==========

export const MAX_BATCH_SIZE = 10; // Maximum tokens per batch claim
export const GAS_BUFFER = 1.2; // 20% gas buffer for estimates

// ========== PROTOCOL NAMES ==========

export const PROTOCOL_NAMES: Record<Protocol, string> = {
  [Protocol.CLANKER_V4]: 'Clanker v4',
  [Protocol.CLANKER_V31]: 'Clanker v3.1',
  [Protocol.CLANKER_V3]: 'Clanker v3.0',
  [Protocol.CLANKER_V2]: 'Clanker v2.0',
  [Protocol.ZORA]: 'Zora',
  [Protocol.FLAUNCH]: 'Flaunch',
  [Protocol.MINT_CLUB]: 'Mint Club',
  [Protocol.AERODROME]: 'Aerodrome',
  [Protocol.UNISWAP_V3]: 'Uniswap V3',
  [Protocol.UNISWAP_V4]: 'Uniswap V4',
};

// ========== EXPORT EXAMPLE USAGE ==========

/*
// Example usage in a React component:

import { useAccount, useContractWrite } from 'wagmi';
import { CONTRACTS, Protocol, buildClaimRequest } from '@/lib/contracts';

function ClaimButton() {
  const { address, chainId } = useAccount();
  const hubAddress = getContractAddress(chainId, 'UniversalClaimHub');

  const { write: claimAll } = useContractWrite({
    address: hubAddress,
    abi: UniversalClaimHubABI,
    functionName: 'batchClaimMultiProtocol',
  });

  const handleClaim = () => {
    const requests = [
      buildClaimRequest(Protocol.CLANKER_V4, ['0x...', '0x...']),
      buildClaimRequest(Protocol.ZORA, ['0x...']),
    ];

    claimAll({ args: [requests] });
  };

  return <button onClick={handleClaim}>Claim All</button>;
}
*/
