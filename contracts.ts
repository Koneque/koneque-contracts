// Koneque Contracts - Base Sepolia Deployment
// Generated on 2025-08-31

export const NETWORK_CONFIG = {
  name: 'Base Sepolia',
  chainId: 84532,
  rpcUrl: 'https://sepolia.base.org',
  explorerUrl: 'https://sepolia.basescan.org',
  currency: {
    name: 'ETH',
    symbol: 'ETH',
    decimals: 18,
  },
} as const;

export const CONTRACT_ADDRESSES = {
  // Token System
  NativeToken: '0x3422820Ef9FBC8e0206E4CBcB6369dBd14BE18c4',
  
  // Account System
  SmartAccount: '0x5B02258b1441F2850a45eb7949d83f6B103e731e',
  AccountFactory: '0x5f7272c1532b6B05558757AAC74e4D21E58DECAe',
  Paymaster: '0x5FCA60cbb22e38F8172ae6BA41FFCfad007a41BD',
  
  // Marketplace System
  MarketplaceCore: '0xbB4fE95d722457484Bc42453d5346a166C7bCAE9',
  Escrow: '0xdE0E60DCaf3e8b36F3C92a9Ea6D97C0e9a3ca194',
  FeeManager: '0x4EF6c34dEEae92d4a6314Ba0C0C76fBe1E8360D0',
  
  // Dispute System
  DisputeResolution: '0x4A1E9765473e4E29EB77250360622c6251D2D4e1',
  OracleRegistry: '0xA6680F13c455655C458807C96AEf1947E87572B2',
  
  // Incentives System
  ReferralSystem: '0xB0EBE476289D5070E18Fb7e4C6F44Ce97Be30211',
} as const;

export const CONTRACT_CATEGORIES = {
  token: ['NativeToken'],
  account: ['SmartAccount', 'AccountFactory', 'Paymaster'],
  marketplace: ['MarketplaceCore', 'Escrow', 'FeeManager'],
  dispute: ['DisputeResolution', 'OracleRegistry'],
  incentives: ['ReferralSystem'],
} as const;

export const CONTRACT_RELATIONSHIPS = {
  MarketplaceCore: {
    dependencies: ['Escrow', 'FeeManager'],
    description: 'Core marketplace functionality with escrow and fee management',
  },
  Escrow: {
    dependencies: ['MarketplaceCore', 'DisputeResolution'],
    description: 'Secure fund custody with dispute resolution integration',
  },
  FeeManager: {
    dependencies: ['MarketplaceCore', 'ReferralSystem'],
    description: 'Platform fee management with referral discounts',
  },
  DisputeResolution: {
    dependencies: ['OracleRegistry', 'Escrow', 'MarketplaceCore'],
    description: 'Dispute resolution with oracle integration',
  },
  ReferralSystem: {
    dependencies: ['FeeManager', 'MarketplaceCore'],
    description: 'Referral tracking and reward distribution',
  },
} as const;

// Utility functions for contract interaction
export const getContractAddress = (contractName: keyof typeof CONTRACT_ADDRESSES): string => {
  return CONTRACT_ADDRESSES[contractName];
};

export const getExplorerUrl = (contractName: keyof typeof CONTRACT_ADDRESSES): string => {
  const address = getContractAddress(contractName);
  return `${NETWORK_CONFIG.explorerUrl}/address/${address}`;
};

export const getContractsByCategory = (category: keyof typeof CONTRACT_CATEGORIES): string[] => {
  return CONTRACT_CATEGORIES[category].map(name => 
    CONTRACT_ADDRESSES[name as keyof typeof CONTRACT_ADDRESSES]
  );
};

// Common contract interactions
export const COMMON_INTERACTIONS = {
  // Native Token
  mintTokens: {
    contract: 'NativeToken',
    method: 'mint',
    signature: 'mint(address,uint256)',
    description: 'Mint tokens to a specific address',
  },
  
  // Account Factory
  createAccount: {
    contract: 'AccountFactory',
    method: 'createAccount',
    signature: 'createAccount(address,uint256)',
    description: 'Create a new smart account',
  },
  
  // Marketplace Core
  createOrder: {
    contract: 'MarketplaceCore',
    method: 'createOrder',
    signature: 'createOrder(...)',
    description: 'Create a new marketplace order',
  },
  
  // Dispute Resolution
  createDispute: {
    contract: 'DisputeResolution',
    method: 'createDispute',
    signature: 'createDispute(uint256,string)',
    description: 'Create a new dispute',
  },
  
  // Referral System
  createReferralCode: {
    contract: 'ReferralSystem',
    method: 'createReferralCode',
    signature: 'createReferralCode(string)',
    description: 'Create a new referral code',
  },
} as const;

// Deployment information
export const DEPLOYMENT_INFO = {
  date: '2025-08-31',
  blockRange: '30431731-30431732',
  totalCost: '0.000015154486445882 ETH',
  deployer: 'YOUR_DEPLOYER_ADDRESS', // Replace with actual deployer address
  version: '1.0.0',
} as const;

// Export types for TypeScript users
export type ContractName = keyof typeof CONTRACT_ADDRESSES;
export type ContractCategory = keyof typeof CONTRACT_CATEGORIES;
export type ContractAddress = typeof CONTRACT_ADDRESSES[ContractName];

// Example usage in React/Next.js:
/*
import { CONTRACT_ADDRESSES, getExplorerUrl } from './contracts';
import { useContract } from 'wagmi';

const MyComponent = () => {
  const nativeTokenContract = useContract({
    address: CONTRACT_ADDRESSES.NativeToken,
    abi: NativeTokenABI, // Import from your ABI files
  });
  
  return (
    <div>
      <a href={getExplorerUrl('NativeToken')} target="_blank">
        View NativeToken on Explorer
      </a>
    </div>
  );
};
*/
