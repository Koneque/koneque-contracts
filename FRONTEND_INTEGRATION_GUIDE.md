# 🌐 Guía de Integración Frontend - Koneque Contracts

## 📋 Tabla de Contenido
- [Configuración Inicial](#configuración-inicial)
- [Integración Web con Privy](#integración-web-con-privy)
- [Integración App con Reown](#integración-app-con-reown)
- [Contratos y ABIs](#contratos-y-abis)
- [Funciones por Flujo](#funciones-por-flujo)
- [Eventos del Sistema](#eventos-del-sistema)
- [Ejemplos Prácticos](#ejemplos-prácticos)
- [Mejores Prácticas](#mejores-prácticas)

---

## 🚀 Configuración Inicial

### Direcciones de Contratos (Base Sepolia)
```javascript
const CONTRACTS = {
  MARKETPLACE_CORE: "0x7fe5708061E76C271a1A9466f73D7667ed0C7Ddd", // MarketplaceCore
  SMART_ACCOUNT_FACTORY: "0x030850c3DEa419bB1c76777F0C2A65c34FB60392", // SmartAccountFactory
  REFERRAL_SYSTEM: "0x747EEC46f064763726603c9C5fC928f99926a209", // ReferralSystem
  NATIVE_TOKEN: "0x697943EF354BFc7c12169D5303cbbB23b133dc53", // NativeToken
  ESCROW: "0x8bbDDc3fcb74CdDB7050552b4DE01415C9966133", // Escrow
  FEE_MANAGER: "0x2212FBb6C244267c23a5710E7e6c4769Ea423beE", // FeeManager
  PAYMASTER: "0x44b89ba09a381F3b598a184A90F039948913dC72", // Paymaster
  DISPUTE_RESOLUTION: "0xD53df29C516D08e1F244Cb5912F0224Ea22B60E1", // DisputeResolution
  ACCOUNT_FACTORY: "0x422478a088ce4d9D9418d4D2C9D99c78fC23393f", // AccountFactory
  SMART_ACCOUNT_IMPL: "0xf24e12Ef8aAcB99FC5843Fc56BEA0BFA5B039BFF", // SmartAccount Implementation
  ORACLE_REGISTRY: "0x3Dd8A23983b94bC208D614C4325D937b710B6E4B" // OracleRegistry
};

const CHAIN_CONFIG = {
  chainId: 84532, // Base Sepolia
  name: "Base Sepolia",
  rpcUrl: "https://sepolia.base.org",
  blockExplorer: "https://sepolia-explorer.base.org"
};
```

---

## 🌐 Integración Web con Privy

### 1. Configuración Inicial de Privy

#### Instalación
```bash
npm install @privy-io/react-auth ethers
```

#### Setup del Provider
```tsx
// providers/PrivyProvider.tsx
'use client';

import { PrivyProvider } from '@privy-io/react-auth';
import { base, baseSepolia } from 'viem/chains';

export default function Providers({ children }: { children: React.ReactNode }) {
  return (
    <PrivyProvider
      appId="your-privy-app-id"
      config={{
        appearance: {
          theme: 'light',
          accentColor: '#676FFF',
          logo: '/logo.png'
        },
        embeddedWallets: {
          createOnLogin: 'users-without-wallets',
          requireUserPasswordOnCreate: true
        },
        defaultChain: baseSepolia,
        supportedChains: [base, baseSepolia],
        loginMethods: ['email', 'sms', 'wallet', 'google'],
        fundingMethodConfig: {
          moonpay: {
            useSandbox: true
          }
        }
      }}
    >
      {children}
    </PrivyProvider>
  );
}
```

#### Layout Principal
```tsx
// app/layout.tsx
import Providers from './providers/PrivyProvider';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es">
      <body>
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  );
}
```

### 2. Hook Personalizado para Contratos

```tsx
// hooks/useContracts.ts
import { usePrivy, useWallets } from '@privy-io/react-auth';
import { ethers } from 'ethers';
import { useMemo } from 'react';

// ABIs (importar desde archivos generados)
import MarketplaceCoreABI from '../abis/MarketplaceCore.json';
import SmartAccountFactoryABI from '../abis/SmartAccountFactory.json';
import ReferralSystemABI from '../abis/ReferralSystem.json';
import NativeTokenABI from '../abis/NativeToken.json';

export const useContracts = () => {
  const { user, authenticated } = usePrivy();
  const { wallets } = useWallets();

  const provider = useMemo(() => {
    if (!wallets[0]) return null;
    return new ethers.providers.Web3Provider(wallets[0].getEthersProvider());
  }, [wallets]);

  const signer = useMemo(() => {
    return provider?.getSigner();
  }, [provider]);

  const contracts = useMemo(() => {
    if (!signer) return null;

    return {
      marketplaceCore: new ethers.Contract(
        CONTRACTS.MARKETPLACE_CORE,
        MarketplaceCoreABI,
        signer
      ),
      smartAccountFactory: new ethers.Contract(
        CONTRACTS.SMART_ACCOUNT_FACTORY,
        SmartAccountFactoryABI,
        signer
      ),
      referralSystem: new ethers.Contract(
        CONTRACTS.REFERRAL_SYSTEM,
        ReferralSystemABI,
        signer
      ),
      nativeToken: new ethers.Contract(
        CONTRACTS.NATIVE_TOKEN,
        NativeTokenABI,
        signer
      )
    };
  }, [signer]);

  return {
    provider,
    signer,
    contracts,
    isConnected: authenticated && !!signer,
    userAddress: wallets[0]?.address
  };
};
```

### 3. Componente de Conexión de Wallet

```tsx
// components/WalletConnect.tsx
import { usePrivy } from '@privy-io/react-auth';
import { useContracts } from '../hooks/useContracts';

export const WalletConnect = () => {
  const { ready, authenticated, login, logout } = usePrivy();
  const { isConnected, userAddress } = useContracts();

  if (!ready) {
    return <div className="loading">Cargando Privy...</div>;
  }

  if (!authenticated) {
    return (
      <button 
        onClick={login}
        className="btn-primary"
      >
        Conectar Wallet
      </button>
    );
  }

  return (
    <div className="wallet-info">
      <p>Conectado: {userAddress}</p>
      <button onClick={logout} className="btn-secondary">
        Desconectar
      </button>
    </div>
  );
};
```

---

## 📱 Integración App con Reown

### 1. Configuración de Flutter

#### Instalación
```yaml
# pubspec.yaml
dependencies:
  reown_appkit: ^1.0.0
  web3dart: ^2.7.3
  http: ^1.1.0
```

#### Configuración Principal
```dart
// lib/services/wallet_service.dart
import 'package:reown_appkit/reown_appkit.dart';
import 'package:web3dart/web3dart.dart';

class WalletService {
  static const String projectId = 'YOUR_REOWN_PROJECT_ID';
  static const int chainId = 84532; // Base Sepolia
  
  late ReownAppKitModal _appKitModal;
  Web3Client? _web3Client;
  
  // Configuración de contratos
  static const Map<String, String> contractAddresses = {
    'MARKETPLACE_CORE': '0x7fe5708061E76C271a1A9466f73D7667ed0C7Ddd',
    'SMART_ACCOUNT_FACTORY': '0x030850c3DEa419bB1c76777F0C2A65c34FB60392',
    'REFERRAL_SYSTEM': '0x747EEC46f064763726603c9C5fC928f99926a209',
    'NATIVE_TOKEN': '0x697943EF354BFc7c12169D5303cbbB23b133dc53',
    'ESCROW': '0x8bbDDc3fcb74CdDB7050552b4DE01415C9966133',
    'FEE_MANAGER': '0x2212FBb6C244267c23a5710E7e6c4769Ea423beE',
    'PAYMASTER': '0x44b89ba09a381F3b598a184A90F039948913dC72',
    'DISPUTE_RESOLUTION': '0xD53df29C516D08e1F244Cb5912F0224Ea22B60E1',
  };

  Future<void> initialize(BuildContext context) async {
    _appKitModal = ReownAppKitModal(
      context: context,
      projectId: projectId,
      metadata: const PairingMetadata(
        name: 'Koneque',
        description: 'Marketplace descentralizado',
        url: 'https://koneque.com',
        icons: ['https://koneque.com/logo.png'],
        redirect: Redirect(
          native: 'koneque://',
          universal: 'https://koneque.com/app',
          linkMode: true,
        ),
      ),
      enableAnalytics: true,
      featuresConfig: const FeaturesConfig(
        analytics: true,
        email: true,
        socials: [AppKitSocialOption.google, AppKitSocialOption.github],
      ),
    );

    await _appKitModal.init();
    
    // Configurar Web3Client
    _web3Client = Web3Client(
      'https://sepolia.base.org',
      Client(),
    );
  }

  ReownAppKitModal get modal => _appKitModal;
  Web3Client? get web3Client => _web3Client;
  
  bool get isConnected => _appKitModal.isConnected;
  String? get address => _appKitModal.session?.address;
}
```

### 2. Widget Principal de la App

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'services/wallet_service.dart';

void main() {
  runApp(KonequeApp());
}

class KonequeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koneque',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late WalletService _walletService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    _walletService = WalletService();
    await _walletService.initialize(context);
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Koneque')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botón de conexión
          AppKitModalConnectButton(appKit: _walletService.modal),
          
          const SizedBox(height: 20),
          
          // Información de cuenta (solo si está conectado)
          if (_walletService.isConnected) ...[
            AppKitModalAccountButton(appKit: _walletService.modal),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MarketplacePage()),
              ),
              child: const Text('Ir al Marketplace'),
            ),
          ],
        ],
      ),
    );
  }
}
```

### 3. Servicio de Contratos para Flutter

```dart
// lib/services/contract_service.dart
import 'package:web3dart/web3dart.dart';
import 'wallet_service.dart';

class ContractService {
  final WalletService _walletService;
  
  ContractService(this._walletService);

  // Cargar ABI desde assets
  Future<ContractAbi> _loadAbi(String contractName) async {
    final abiString = await rootBundle.loadString('assets/abis/$contractName.json');
    return ContractAbi.fromJson(abiString, contractName);
  }

  // Crear instancia de contrato
  Future<DeployedContract> _getContract(String contractName, String address) async {
    final abi = await _loadAbi(contractName);
    return DeployedContract(abi, EthereumAddress.fromHex(address));
  }

  // Listar item en marketplace
  Future<String> listItem({
    required BigInt price,
    required String metadataURI,
    required String category,
  }) async {
    final contract = await _getContract(
      'MarketplaceCore',
      WalletService.contractAddresses['MARKETPLACE_CORE']!,
    );

    final function = contract.function('listItem');
    final transaction = Transaction.callContract(
      contract: contract,
      function: function,
      parameters: [price, metadataURI, category],
    );

    final txHash = await _walletService.web3Client!.sendTransaction(
      _getCredentials(),
      transaction,
      chainId: WalletService.chainId,
    );

    return txHash;
  }

  // Comprar item
  Future<String> buyItem(BigInt itemId) async {
    final contract = await _getContract(
      'MarketplaceCore',
      WalletService.contractAddresses['MARKETPLACE_CORE']!,
    );

    final function = contract.function('buyItem');
    final transaction = Transaction.callContract(
      contract: contract,
      function: function,
      parameters: [itemId],
    );

    final txHash = await _walletService.web3Client!.sendTransaction(
      _getCredentials(),
      transaction,
      chainId: WalletService.chainId,
    );

    return txHash;
  }

  // Crear Smart Account
  Future<String> createSmartAccount() async {
    final contract = await _getContract(
      'SmartAccountFactory',
      WalletService.contractAddresses['SMART_ACCOUNT_FACTORY']!,
    );

    final function = contract.function('createSmartAccountAutoSalt');
    final transaction = Transaction.callContract(
      contract: contract,
      function: function,
      parameters: [EthereumAddress.fromHex(_walletService.address!)],
    );

    final txHash = await _walletService.web3Client!.sendTransaction(
      _getCredentials(),
      transaction,
      chainId: WalletService.chainId,
    );

    return txHash;
  }

  // Obtener credenciales (implementar según tu método de firma)
  Credentials _getCredentials() {
    // Implementar según cómo manejes las claves privadas
    // En producción, usar métodos seguros como hardware wallets
    throw UnimplementedError('Implementar método de credenciales');
  }
}
```

---

## 📄 Contratos y ABIs

### Estructura de ABIs Necesarias

```typescript
// types/contracts.ts
export interface MarketplaceCoreABI {
  listItem(price: bigint, metadataURI: string, category: string): Promise<bigint>;
  buyItem(itemId: bigint): Promise<bigint>;
  buyBatch(itemIds: bigint[]): Promise<bigint[]>;
  cancelListing(itemId: bigint): Promise<void>;
  confirmDelivery(transactionId: bigint): Promise<void>;
  finalizeTransaction(transactionId: bigint): Promise<void>;
  initiateDispute(transactionId: bigint): Promise<void>;
  getItemDetails(itemId: bigint): Promise<Item>;
  getActiveListings(): Promise<Item[]>;
  getUserItems(user: string): Promise<bigint[]>;
  getUserTransactions(user: string): Promise<bigint[]>;
  getTransactionDetails(transactionId: bigint): Promise<Transaction>;
}

export interface SmartAccountFactoryABI {
  createSmartAccount(owner: string, salt: string): Promise<string>;
  createSmartAccountAutoSalt(owner: string): Promise<string>;
  getSmartAccountAddress(salt: string): Promise<string>;
  getUserAccounts(user: string): Promise<string[]>;
  isValidSmartAccount(account: string): Promise<boolean>;
}

export interface ReferralSystemABI {
  createReferralCode(code: string, validityPeriod: bigint, maxUsage: bigint): Promise<void>;
  registerReferralWithCode(code: string, referred: string): Promise<void>;
  registerReferral(referrer: string, referred: string): Promise<void>;
  claimReferralReward(referred: string): Promise<void>;
  getReferralStats(referrer: string): Promise<[bigint, bigint]>;
  validateReferralEligibility(referred: string): Promise<boolean>;
  getReferralCodeInfo(code: string): Promise<ReferralCode>;
  isReferralCodeValid(code: string): Promise<boolean>;
}
```

---

## 🔄 Funciones por Flujo

### 1. Flujo de Marketplace

#### Web (React + Privy)
```tsx
// components/Marketplace.tsx
import { useContracts } from '../hooks/useContracts';
import { useState, useEffect } from 'react';

export const Marketplace = () => {
  const { contracts, isConnected } = useContracts();
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(false);

  // Listar item
  const listItem = async (price: string, metadataURI: string, category: string) => {
    if (!contracts) return;
    
    setLoading(true);
    try {
      const priceWei = ethers.utils.parseEther(price);
      const tx = await contracts.marketplaceCore.listItem(priceWei, metadataURI, category);
      await tx.wait();
      
      // Recargar items
      await loadItems();
    } catch (error) {
      console.error('Error listing item:', error);
    } finally {
      setLoading(false);
    }
  };

  // Cargar items activos
  const loadItems = async () => {
    if (!contracts) return;
    
    try {
      const activeItems = await contracts.marketplaceCore.getActiveListings();
      setItems(activeItems);
    } catch (error) {
      console.error('Error loading items:', error);
    }
  };

  // Comprar item
  const buyItem = async (itemId: number) => {
    if (!contracts) return;
    
    setLoading(true);
    try {
      // Verificar balance y aprobación
      const item = await contracts.marketplaceCore.getItemDetails(itemId);
      const balance = await contracts.nativeToken.balanceOf(userAddress);
      
      if (balance.lt(item.price)) {
        throw new Error('Balance insuficiente');
      }

      // Aprobar tokens si es necesario
      const allowance = await contracts.nativeToken.allowance(userAddress, CONTRACTS.MARKETPLACE_CORE);
      if (allowance.lt(item.price)) {
        const approveTx = await contracts.nativeToken.approve(CONTRACTS.MARKETPLACE_CORE, item.price);
        await approveTx.wait();
      }

      // Comprar item
      const tx = await contracts.marketplaceCore.buyItem(itemId);
      await tx.wait();
      
      // Recargar items
      await loadItems();
    } catch (error) {
      console.error('Error buying item:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (isConnected) {
      loadItems();
    }
  }, [isConnected]);

  return (
    <div className="marketplace">
      <h2>Marketplace</h2>
      
      {/* Formulario para listar item */}
      <ItemListingForm onSubmit={listItem} loading={loading} />
      
      {/* Lista de items */}
      <div className="items-grid">
        {items.map(item => (
          <ItemCard 
            key={item.id} 
            item={item} 
            onBuy={() => buyItem(item.id)}
            loading={loading}
          />
        ))}
      </div>
    </div>
  );
};
```

#### App (Flutter + Reown)
```dart
// lib/pages/marketplace_page.dart
import 'package:flutter/material.dart';
import '../services/contract_service.dart';
import '../services/wallet_service.dart';

class MarketplacePage extends StatefulWidget {
  @override
  _MarketplacePageState createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  late ContractService _contractService;
  late WalletService _walletService;
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _walletService = WalletService();
    _contractService = ContractService(_walletService);
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    
    try {
      // Implementar carga de items activos
      final items = await _contractService.getActiveListings();
      setState(() => _items = items);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando items: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _buyItem(BigInt itemId) async {
    setState(() => _loading = true);
    
    try {
      final txHash = await _contractService.buyItem(itemId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compra exitosa! Tx: $txHash')),
      );
      
      await _loadItems(); // Recargar items
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en compra: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ItemCard(
                  item: item,
                  onBuy: () => _buyItem(BigInt.from(item['id'])),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showListItemDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showListItemDialog() {
    // Implementar diálogo para listar nuevo item
  }
}
```

### 2. Flujo de Smart Account

#### Creación Automática en Web
```tsx
// hooks/useSmartAccount.ts
import { useContracts } from './useContracts';
import { useState, useEffect } from 'react';

export const useSmartAccount = () => {
  const { contracts, userAddress, isConnected } = useContracts();
  const [smartAccounts, setSmartAccounts] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);

  // Verificar si el usuario ya tiene Smart Accounts
  const checkExistingAccounts = async () => {
    if (!contracts || !userAddress) return;
    
    try {
      const accounts = await contracts.smartAccountFactory.getUserAccounts(userAddress);
      setSmartAccounts(accounts);
    } catch (error) {
      console.error('Error checking accounts:', error);
    }
  };

  // Crear Smart Account automáticamente
  const createSmartAccount = async () => {
    if (!contracts || !userAddress) return null;
    
    setLoading(true);
    try {
      const tx = await contracts.smartAccountFactory.createSmartAccountAutoSalt(userAddress);
      const receipt = await tx.wait();
      
      // Buscar evento SmartAccountCreated
      const event = receipt.events?.find(e => e.event === 'SmartAccountCreated');
      const smartAccountAddress = event?.args?.smartAccount;
      
      if (smartAccountAddress) {
        setSmartAccounts(prev => [...prev, smartAccountAddress]);
        return smartAccountAddress;
      }
    } catch (error) {
      console.error('Error creating smart account:', error);
    } finally {
      setLoading(false);
    }
    
    return null;
  };

  // Auto-crear Smart Account en primera conexión
  useEffect(() => {
    if (isConnected && userAddress) {
      checkExistingAccounts().then(() => {
        // Si no tiene Smart Accounts, crear una automáticamente
        if (smartAccounts.length === 0) {
          createSmartAccount();
        }
      });
    }
  }, [isConnected, userAddress]);

  return {
    smartAccounts,
    createSmartAccount,
    loading,
    hasSmartAccount: smartAccounts.length > 0
  };
};
```

#### Creación en App
```dart
// lib/services/smart_account_service.dart
class SmartAccountService {
  final ContractService _contractService;
  
  SmartAccountService(this._contractService);

  Future<String?> createSmartAccountIfNeeded(String userAddress) async {
    try {
      // Verificar si ya tiene Smart Accounts
      final existingAccounts = await _contractService.getUserSmartAccounts(userAddress);
      
      if (existingAccounts.isNotEmpty) {
        return existingAccounts.first; // Retornar la primera cuenta existente
      }

      // Crear nueva Smart Account
      final txHash = await _contractService.createSmartAccount();
      
      // Esperar confirmación y obtener dirección
      final receipt = await _contractService.getTransactionReceipt(txHash);
      final smartAccountAddress = _extractSmartAccountAddress(receipt);
      
      return smartAccountAddress;
    } catch (e) {
      print('Error creating smart account: $e');
      return null;
    }
  }

  String? _extractSmartAccountAddress(Map<String, dynamic> receipt) {
    // Implementar extracción de dirección desde logs del evento
    final logs = receipt['logs'] as List?;
    if (logs != null) {
      for (final log in logs) {
        // Buscar evento SmartAccountCreated
        if (log['topics']?.length >= 2) {
          // Decodificar dirección de Smart Account desde los topics
          return log['topics'][1]; // Simplificado
        }
      }
    }
    return null;
  }
}
```

### 3. Flujo de Referidos

#### Crear y Usar Códigos de Referido (Web)
```tsx
// components/ReferralSystem.tsx
import { useContracts } from '../hooks/useContracts';
import { useState } from 'react';

export const ReferralSystem = () => {
  const { contracts, userAddress } = useContracts();
  const [code, setCode] = useState('');
  const [referralStats, setReferralStats] = useState({ totalReferrals: 0, totalRewards: 0 });

  // Crear código de referido
  const createReferralCode = async (code: string, days: number, maxUsage: number) => {
    if (!contracts) return;
    
    try {
      const validityPeriod = days * 24 * 60 * 60; // días a segundos
      const tx = await contracts.referralSystem.createReferralCode(
        code, 
        validityPeriod, 
        maxUsage
      );
      await tx.wait();
      
      alert('Código de referido creado exitosamente!');
    } catch (error) {
      console.error('Error creating referral code:', error);
    }
  };

  // Usar código de referido
  const useReferralCode = async (code: string) => {
    if (!contracts || !userAddress) return;
    
    try {
      // Verificar si el código es válido
      const isValid = await contracts.referralSystem.isReferralCodeValid(code);
      if (!isValid) {
        throw new Error('Código de referido inválido o expirado');
      }

      const tx = await contracts.referralSystem.registerReferralWithCode(code, userAddress);
      await tx.wait();
      
      alert('¡Te has registrado con el código de referido!');
    } catch (error) {
      console.error('Error using referral code:', error);
    }
  };

  // Reclamar recompensa de referido
  const claimReferralReward = async (referredAddress: string) => {
    if (!contracts) return;
    
    try {
      const tx = await contracts.referralSystem.claimReferralReward(referredAddress);
      await tx.wait();
      
      alert('¡Recompensa reclamada exitosamente!');
      loadReferralStats(); // Recargar estadísticas
    } catch (error) {
      console.error('Error claiming reward:', error);
    }
  };

  // Cargar estadísticas de referidos
  const loadReferralStats = async () => {
    if (!contracts || !userAddress) return;
    
    try {
      const [totalReferrals, totalRewards] = await contracts.referralSystem.getReferralStats(userAddress);
      setReferralStats({
        totalReferrals: totalReferrals.toNumber(),
        totalRewards: ethers.utils.formatEther(totalRewards)
      });
    } catch (error) {
      console.error('Error loading stats:', error);
    }
  };

  return (
    <div className="referral-system">
      <h3>Sistema de Referidos</h3>
      
      {/* Crear código */}
      <div className="create-code">
        <input 
          value={code}
          onChange={(e) => setCode(e.target.value)}
          placeholder="Código de referido"
        />
        <button onClick={() => createReferralCode(code, 365, 100)}>
          Crear Código
        </button>
      </div>

      {/* Usar código */}
      <div className="use-code">
        <input 
          placeholder="Código para usar"
          onBlur={(e) => useReferralCode(e.target.value)}
        />
      </div>

      {/* Estadísticas */}
      <div className="stats">
        <p>Total Referidos: {referralStats.totalReferrals}</p>
        <p>Recompensas Totales: {referralStats.totalRewards} KNQ</p>
      </div>
    </div>
  );
};
```

---

## 🎯 Eventos del Sistema

### 1. Escuchar Eventos en Web

```tsx
// hooks/useMarketplaceEvents.ts
import { useContracts } from './useContracts';
import { useEffect, useState } from 'react';

export const useMarketplaceEvents = () => {
  const { contracts } = useContracts();
  const [events, setEvents] = useState([]);

  useEffect(() => {
    if (!contracts) return;

    // Eventos del marketplace
    const filters = {
      ItemListed: contracts.marketplaceCore.filters.ItemListed(),
      ItemPurchased: contracts.marketplaceCore.filters.ItemPurchased(),
      DeliveryConfirmed: contracts.marketplaceCore.filters.DeliveryConfirmed(),
      TransactionFinalized: contracts.marketplaceCore.filters.TransactionFinalized(),
    };

    // Configurar listeners
    Object.entries(filters).forEach(([eventName, filter]) => {
      contracts.marketplaceCore.on(filter, (...args) => {
        const event = {
          type: eventName,
          data: args,
          timestamp: new Date(),
        };
        
        setEvents(prev => [...prev, event]);
        
        // Mostrar notificación
        showNotification(eventName, args);
      });
    });

    // Cleanup
    return () => {
      Object.values(filters).forEach(filter => {
        contracts.marketplaceCore.removeAllListeners(filter);
      });
    };
  }, [contracts]);

  const showNotification = (eventName: string, args: any[]) => {
    switch (eventName) {
      case 'ItemListed':
        toast.success(`Nuevo item listado por ${args[1]}`);
        break;
      case 'ItemPurchased':
        toast.success(`Item comprado por ${args[2]}`);
        break;
      case 'DeliveryConfirmed':
        toast.info(`Entrega confirmada para transacción ${args[0]}`);
        break;
      case 'TransactionFinalized':
        toast.success(`Transacción ${args[0]} finalizada`);
        break;
    }
  };

  return { events };
};
```

### 2. Escuchar Eventos en App

```dart
// lib/services/event_service.dart
import 'dart:async';
import 'package:web3dart/web3dart.dart';

class EventService {
  final Web3Client _web3Client;
  final Map<String, DeployedContract> _contracts;
  
  final _eventController = StreamController<ContractEvent>.broadcast();
  
  EventService(this._web3Client, this._contracts);

  Stream<ContractEvent> get events => _eventController.stream;

  void startListening() {
    // Escuchar eventos del marketplace
    _listenToMarketplaceEvents();
    _listenToReferralEvents();
    _listenToSmartAccountEvents();
  }

  void _listenToMarketplaceEvents() {
    final contract = _contracts['MarketplaceCore']!;
    
    // ItemListed event
    final itemListedFilter = FilterOptions.events(
      contract: contract,
      event: contract.event('ItemListed'),
    );
    
    _web3Client.events(itemListedFilter).listen((FilterEvent event) {
      _eventController.add(ContractEvent(
        type: 'ItemListed',
        data: event.topics,
        blockNumber: event.blockNumber,
        transactionHash: event.transactionHash,
      ));
    });

    // ItemPurchased event
    final itemPurchasedFilter = FilterOptions.events(
      contract: contract,
      event: contract.event('ItemPurchased'),
    );
    
    _web3Client.events(itemPurchasedFilter).listen((FilterEvent event) {
      _eventController.add(ContractEvent(
        type: 'ItemPurchased',
        data: event.topics,
        blockNumber: event.blockNumber,
        transactionHash: event.transactionHash,
      ));
    });
  }

  void _listenToReferralEvents() {
    final contract = _contracts['ReferralSystem']!;
    
    final referralRegisteredFilter = FilterOptions.events(
      contract: contract,
      event: contract.event('ReferralRegistered'),
    );
    
    _web3Client.events(referralRegisteredFilter).listen((FilterEvent event) {
      _eventController.add(ContractEvent(
        type: 'ReferralRegistered',
        data: event.topics,
        blockNumber: event.blockNumber,
        transactionHash: event.transactionHash,
      ));
    });
  }

  void _listenToSmartAccountEvents() {
    final contract = _contracts['SmartAccountFactory']!;
    
    final accountCreatedFilter = FilterOptions.events(
      contract: contract,
      event: contract.event('SmartAccountCreated'),
    );
    
    _web3Client.events(accountCreatedFilter).listen((FilterEvent event) {
      _eventController.add(ContractEvent(
        type: 'SmartAccountCreated',
        data: event.topics,
        blockNumber: event.blockNumber,
        transactionHash: event.transactionHash,
      ));
    });
  }

  void dispose() {
    _eventController.close();
  }
}

class ContractEvent {
  final String type;
  final List<String> data;
  final int? blockNumber;
  final String? transactionHash;

  ContractEvent({
    required this.type,
    required this.data,
    this.blockNumber,
    this.transactionHash,
  });
}
```

---

## 💡 Ejemplos Prácticos

### 1. Flujo Completo de Compra (Web)

```tsx
// components/PurchaseFlow.tsx
import { useState } from 'react';
import { useContracts } from '../hooks/useContracts';
import { useSmartAccount } from '../hooks/useSmartAccount';

export const PurchaseFlow = ({ itemId }: { itemId: number }) => {
  const { contracts, userAddress } = useContracts();
  const { hasSmartAccount, createSmartAccount } = useSmartAccount();
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);

  const handlePurchase = async () => {
    setLoading(true);
    
    try {
      // Paso 1: Verificar/crear Smart Account
      if (!hasSmartAccount) {
        setStep(2);
        await createSmartAccount();
      }

      // Paso 2: Verificar balance y aprobar tokens
      setStep(3);
      const item = await contracts.marketplaceCore.getItemDetails(itemId);
      const balance = await contracts.nativeToken.balanceOf(userAddress);
      
      if (balance.lt(item.price)) {
        throw new Error('Balance insuficiente');
      }

      const allowance = await contracts.nativeToken.allowance(
        userAddress, 
        CONTRACTS.MARKETPLACE_CORE
      );
      
      if (allowance.lt(item.price)) {
        const approveTx = await contracts.nativeToken.approve(
          CONTRACTS.MARKETPLACE_CORE, 
          item.price
        );
        await approveTx.wait();
      }

      // Paso 3: Realizar compra
      setStep(4);
      const buyTx = await contracts.marketplaceCore.buyItem(itemId);
      const receipt = await buyTx.wait();

      // Paso 4: Confirmar transacción
      setStep(5);
      const purchaseEvent = receipt.events?.find(e => e.event === 'ItemPurchased');
      const transactionId = purchaseEvent?.args?.transactionId;

      if (transactionId) {
        // Automáticamente confirmar entrega después de un tiempo
        setTimeout(async () => {
          try {
            const confirmTx = await contracts.marketplaceCore.confirmDelivery(transactionId);
            await confirmTx.wait();
            
            // Finalizar transacción
            const finalizeTx = await contracts.marketplaceCore.finalizeTransaction(transactionId);
            await finalizeTx.wait();
            
            setStep(6);
          } catch (error) {
            console.error('Error in delivery confirmation:', error);
          }
        }, 10000); // 10 segundos para demo
      }

    } catch (error) {
      console.error('Purchase flow error:', error);
      alert(`Error: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const getStepMessage = () => {
    switch (step) {
      case 1: return 'Listo para comprar';
      case 2: return 'Creando Smart Account...';
      case 3: return 'Verificando balance y approbaciones...';
      case 4: return 'Procesando compra...';
      case 5: return 'Esperando confirmación de entrega...';
      case 6: return '¡Compra completada exitosamente!';
      default: return '';
    }
  };

  return (
    <div className="purchase-flow">
      <div className="step-indicator">
        Paso {step}/6: {getStepMessage()}
      </div>
      
      <button 
        onClick={handlePurchase}
        disabled={loading || step > 1}
        className="purchase-btn"
      >
        {loading ? 'Procesando...' : 'Comprar Item'}
      </button>
      
      {step === 6 && (
        <div className="success-message">
          ✅ ¡Compra realizada exitosamente!
        </div>
      )}
    </div>
  );
};
```

### 2. Dashboard de Usuario (App)

```dart
// lib/pages/user_dashboard.dart
import 'package:flutter/material.dart';

class UserDashboard extends StatefulWidget {
  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  Map<String, dynamic> _userStats = {};
  List<Map<String, dynamic>> _userTransactions = [];
  List<String> _smartAccounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Cargar estadísticas del usuario
      _userStats = await _contractService.getUserStats();
      
      // Cargar transacciones
      _userTransactions = await _contractService.getUserTransactions();
      
      // Cargar Smart Accounts
      _smartAccounts = await _contractService.getUserSmartAccounts();
      
      setState(() => _loading = false);
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de estadísticas
            _buildStatsSection(),
            
            const SizedBox(height: 24),
            
            // Smart Accounts
            _buildSmartAccountsSection(),
            
            const SizedBox(height: 24),
            
            // Transacciones recientes
            _buildTransactionsSection(),
            
            const SizedBox(height: 24),
            
            // Referidos
            _buildReferralsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Items Comprados', _userStats['itemsBought']?.toString() ?? '0'),
                _buildStatItem('Items Vendidos', _userStats['itemsSold']?.toString() ?? '0'),
                _buildStatItem('Balance KNQ', _userStats['balance']?.toString() ?? '0'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSmartAccountsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Smart Accounts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: _createNewSmartAccount,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._smartAccounts.map((account) => ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: Text(account.substring(0, 10) + '...'),
              subtitle: const Text('Smart Account'),
              trailing: IconButton(
                onPressed: () => _copyToClipboard(account),
                icon: const Icon(Icons.copy),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transacciones Recientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._userTransactions.take(5).map((tx) => ListTile(
              leading: Icon(
                tx['type'] == 'buy' ? Icons.shopping_cart : Icons.sell,
                color: tx['type'] == 'buy' ? Colors.red : Colors.green,
              ),
              title: Text(tx['type'] == 'buy' ? 'Compra' : 'Venta'),
              subtitle: Text('Item ID: ${tx['itemId']}'),
              trailing: Text('${tx['amount']} KNQ'),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sistema de Referidos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Referidos', _userStats['totalReferrals']?.toString() ?? '0'),
                _buildStatItem('Recompensas', _userStats['totalRewards']?.toString() ?? '0'),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showCreateReferralCodeDialog,
              child: const Text('Crear Código de Referido'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createNewSmartAccount() async {
    try {
      final address = await _contractService.createSmartAccount();
      if (address != null) {
        setState(() {
          _smartAccounts.add(address);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Smart Account creada exitosamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creando Smart Account: $e')),
      );
    }
  }

  void _copyToClipboard(String text) {
    // Implementar copia al portapapeles
  }

  void _showCreateReferralCodeDialog() {
    // Implementar diálogo para crear código de referido
  }
}
```

---

## 🛡️ Mejores Prácticas

### 1. Manejo de Errores

```tsx
// utils/errorHandler.ts
export class ContractError extends Error {
  constructor(
    message: string,
    public code?: string,
    public data?: any
  ) {
    super(message);
    this.name = 'ContractError';
  }
}

export const handleContractError = (error: any): string => {
  if (error.code === 'UNPREDICTABLE_GAS_LIMIT') {
    return 'Error en la estimación de gas. Verifica los parámetros.';
  }
  
  if (error.code === 'INSUFFICIENT_FUNDS') {
    return 'Fondos insuficientes para realizar la transacción.';
  }
  
  if (error.message?.includes('User rejected')) {
    return 'Transacción cancelada por el usuario.';
  }
  
  if (error.message?.includes('execution reverted')) {
    // Extraer mensaje de error del contrato
    const revertReason = error.message.split('execution reverted: ')[1];
    return revertReason || 'Error en la ejecución del contrato.';
  }
  
  return error.message || 'Error desconocido en el contrato.';
};
```

### 2. Optimización de Gas

```tsx
// utils/gasOptimization.ts
export const estimateGasWithBuffer = async (
  contract: ethers.Contract,
  method: string,
  params: any[],
  bufferPercent: number = 20
): Promise<ethers.BigNumber> => {
  try {
    const estimated = await contract.estimateGas[method](...params);
    const buffer = estimated.mul(bufferPercent).div(100);
    return estimated.add(buffer);
  } catch (error) {
    console.error('Gas estimation failed:', error);
    // Fallback gas limit
    return ethers.BigNumber.from('300000');
  }
};

export const getCurrentGasPrice = async (provider: ethers.providers.Provider): Promise<ethers.BigNumber> => {
  try {
    const gasPrice = await provider.getGasPrice();
    // Agregar 10% extra para asegurar que la transacción sea procesada
    return gasPrice.mul(110).div(100);
  } catch (error) {
    console.error('Failed to get gas price:', error);
    return ethers.utils.parseUnits('20', 'gwei'); // Fallback
  }
};
```

### 3. Caché y Persistencia

```tsx
// utils/storage.ts
export class ContractDataCache {
  private static instance: ContractDataCache;
  private cache = new Map<string, { data: any; timestamp: number; ttl: number }>();

  static getInstance(): ContractDataCache {
    if (!ContractDataCache.instance) {
      ContractDataCache.instance = new ContractDataCache();
    }
    return ContractDataCache.instance;
  }

  set(key: string, data: any, ttlMinutes: number = 5): void {
    this.cache.set(key, {
      data,
      timestamp: Date.now(),
      ttl: ttlMinutes * 60 * 1000
    });
  }

  get(key: string): any | null {
    const item = this.cache.get(key);
    if (!item) return null;

    if (Date.now() - item.timestamp > item.ttl) {
      this.cache.delete(key);
      return null;
    }

    return item.data;
  }

  invalidate(pattern: string): void {
    for (const key of this.cache.keys()) {
      if (key.includes(pattern)) {
        this.cache.delete(key);
      }
    }
  }

  clear(): void {
    this.cache.clear();
  }
}

// Hook para usar el caché
export const useCachedContractCall = <T>(
  key: string,
  contractCall: () => Promise<T>,
  ttlMinutes: number = 5
) => {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(false);
  const cache = ContractDataCache.getInstance();

  const fetchData = async (useCache: boolean = true) => {
    if (useCache) {
      const cachedData = cache.get(key);
      if (cachedData) {
        setData(cachedData);
        return cachedData;
      }
    }

    setLoading(true);
    try {
      const result = await contractCall();
      cache.set(key, result, ttlMinutes);
      setData(result);
      return result;
    } catch (error) {
      console.error(`Error fetching ${key}:`, error);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [key]);

  return { data, loading, refetch: () => fetchData(false) };
};
```

### 4. Validación de Transacciones

```dart
// lib/utils/transaction_validator.dart
class TransactionValidator {
  static Future<ValidationResult> validatePurchase({
    required String userAddress,
    required BigInt itemId,
    required BigInt itemPrice,
    required BigInt userBalance,
  }) async {
    final errors = <String>[];

    // Validar balance
    if (userBalance < itemPrice) {
      errors.add('Balance insuficiente. Necesitas ${itemPrice.toString()} KNQ');
    }

    // Validar que el item esté disponible
    try {
      final item = await ContractService.getItemDetails(itemId);
      if (!item['isActive']) {
        errors.add('El item ya no está disponible');
      }
      
      if (item['seller'].toLowerCase() == userAddress.toLowerCase()) {
        errors.add('No puedes comprar tu propio item');
      }
    } catch (e) {
      errors.add('Error validando item: $e');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  static Future<ValidationResult> validateReferralCode(String code) async {
    final errors = <String>[];

    if (code.isEmpty) {
      errors.add('El código de referido no puede estar vacío');
    }

    if (code.length > 32) {
      errors.add('El código de referido es demasiado largo');
    }

    try {
      final isValid = await ContractService.isReferralCodeValid(code);
      if (!isValid) {
        errors.add('El código de referido es inválido o ha expirado');
      }
    } catch (e) {
      errors.add('Error validando código de referido: $e');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({required this.isValid, required this.errors});
}
```

---

## 🔧 Configuración de Desarrollo

### Variables de Entorno

#### Web (.env)
```bash
# Privy
NEXT_PUBLIC_PRIVY_APP_ID=your_privy_app_id
NEXT_PUBLIC_PRIVY_CLIENT_ID=your_client_id

# Contratos (Base Sepolia)
NEXT_PUBLIC_MARKETPLACE_CORE=0x7fe5708061E76C271a1A9466f73D7667ed0C7Ddd
NEXT_PUBLIC_SMART_ACCOUNT_FACTORY=0x030850c3DEa419bB1c76777F0C2A65c34FB60392
NEXT_PUBLIC_REFERRAL_SYSTEM=0x747EEC46f064763726603c9C5fC928f99926a209
NEXT_PUBLIC_NATIVE_TOKEN=0x697943EF354BFc7c12169D5303cbbB23b133dc53
NEXT_PUBLIC_ESCROW=0x8bbDDc3fcb74CdDB7050552b4DE01415C9966133
NEXT_PUBLIC_FEE_MANAGER=0x2212FBb6C244267c23a5710E7e6c4769Ea423beE
NEXT_PUBLIC_PAYMASTER=0x44b89ba09a381F3b598a184A90F039948913dC72
NEXT_PUBLIC_DISPUTE_RESOLUTION=0xD53df29C516D08e1F244Cb5912F0224Ea22B60E1

# Red
NEXT_PUBLIC_CHAIN_ID=84532
NEXT_PUBLIC_RPC_URL=https://sepolia.base.org
```

#### App (Flutter - .env)
```bash
# Reown
REOWN_PROJECT_ID=your_reown_project_id

# Contratos (Base Sepolia)
MARKETPLACE_CORE=0x7fe5708061E76C271a1A9466f73D7667ed0C7Ddd
SMART_ACCOUNT_FACTORY=0x030850c3DEa419bB1c76777F0C2A65c34FB60392
REFERRAL_SYSTEM=0x747EEC46f064763726603c9C5fC928f99926a209
NATIVE_TOKEN=0x697943EF354BFc7c12169D5303cbbB23b133dc53
ESCROW=0x8bbDDc3fcb74CdDB7050552b4DE01415C9966133
FEE_MANAGER=0x2212FBb6C244267c23a5710E7e6c4769Ea423beE
PAYMASTER=0x44b89ba09a381F3b598a184A90F039948913dC72
DISPUTE_RESOLUTION=0xD53df29C516D08e1F244Cb5912F0224Ea22B60E1

# Red
CHAIN_ID=84532
RPC_URL=https://sepolia.base.org
```

### Scripts de Deployment

```javascript
// scripts/deploy-and-configure.js
const { ethers } = require('ethers');
require('dotenv').config();

async function deployAndConfigure() {
  const provider = new ethers.providers.JsonRpcProvider(process.env.BASE_SEPOLIA_RPC_URL);
  const deployer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  console.log('Deploying contracts...');
  
  // Desplegar contratos
  const contracts = await deployAllContracts(deployer);
  
  // Configurar interacciones entre contratos
  await configureContracts(contracts);
  
  // Generar archivo de configuración para frontend
  await generateFrontendConfig(contracts);
  
  console.log('Deployment completed!');
}

async function generateFrontendConfig(contracts) {
  const config = {
    CONTRACTS: {
      MARKETPLACE_CORE: "0x7fe5708061E76C271a1A9466f73D7667ed0C7Ddd",
      SMART_ACCOUNT_FACTORY: "0x030850c3DEa419bB1c76777F0C2A65c34FB60392",
      REFERRAL_SYSTEM: "0x747EEC46f064763726603c9C5fC928f99926a209",
      NATIVE_TOKEN: "0x697943EF354BFc7c12169D5303cbbB23b133dc53",
      ESCROW: "0x8bbDDc3fcb74CdDB7050552b4DE01415C9966133",
      FEE_MANAGER: "0x2212FBb6C244267c23a5710E7e6c4769Ea423beE",
      PAYMASTER: "0x44b89ba09a381F3b598a184A90F039948913dC72",
      DISPUTE_RESOLUTION: "0xD53df29C516D08e1F244Cb5912F0224Ea22B60E1",
      ACCOUNT_FACTORY: "0x422478a088ce4d9D9418d4D2C9D99c78fC23393f",
      SMART_ACCOUNT_IMPL: "0xf24e12Ef8aAcB99FC5843Fc56BEA0BFA5B039BFF",
      ORACLE_REGISTRY: "0x3Dd8A23983b94bC208D614C4325D937b710B6E4B"
    },
    CHAIN_CONFIG: {
      chainId: 84532,
      name: "Base Sepolia",
      rpcUrl: "https://sepolia.base.org",
      blockExplorer: "https://sepolia-explorer.base.org"
    }
  };

  // Guardar configuración para web
  fs.writeFileSync('./frontend-web/config/contracts.json', JSON.stringify(config, null, 2));
  
  // Guardar configuración para app
  fs.writeFileSync('./frontend-app/assets/config/contracts.json', JSON.stringify(config, null, 2));
}
```

---

Esta guía proporciona una base sólida para integrar los contratos de Koneque con tanto aplicaciones web usando Privy como aplicaciones móviles usando Reown. Incluye ejemplos prácticos, manejo de errores, optimizaciones y mejores prácticas para un desarrollo robusto y escalable.
