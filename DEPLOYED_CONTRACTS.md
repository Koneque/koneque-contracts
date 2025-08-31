# 📋 Contratos Deployados - Koneque

## 🚀 Red: Base Sepolia (ChainID: 84532)

### 📄 Direcciones de Contratos

| Contrato | Dirección | Explorer |
|----------|-----------|----------|
| **NativeToken** | `0x697943EF354BFc7c12169D5303cbbB23b133dc53` | [Ver en BaseScan](https://sepolia.basescan.org/address/0x697943EF354BFc7c12169D5303cbbB23b133dc53) |
| **SmartAccount (Implementation)** | `0xf24e12Ef8aAcB99FC5843Fc56BEA0BFA5B039BFF` | [Ver en BaseScan](https://sepolia.basescan.org/address/0xf24e12Ef8aAcB99FC5843Fc56BEA0BFA5B039BFF) |
| **AccountFactory** | `0x422478a088ce4d9D9418d4D2C9D99c78fC23393f` | [Ver en BaseScan](https://sepolia.basescan.org/address/0x422478a088ce4d9D9418d4D2C9D99c78fC23393f) |
| **SmartAccountFactory** | `0x030850c3DEa419bB1c76777F0C2A65c34FB60392` | [Ver en BaseScan](https://sepolia.basescan.org/address/0x030850c3DEa419bB1c76777F0C2A65c34FB60392) |
| **Paymaster** | `0x44b89ba09a381F3b598a184A90F039948913dC72` | [Ver en BaseScan](https://sepolia.basescan.org/address/0x44b89ba09a381F3b598a184A90F039948913dC72) |
| **Escrow** | `0x8bbDDc3fcb74CdDB7050552b4DE01415C9966133` | [Ver en BaseScan](https://sepolia.basescan.org/address/0x8bbDDc3fcb74CdDB7050552b4DE01415C9966133) |
| **FeeManager** | `0x2212FBb6C244267c23a5710E7e6c4769Ea423beE` | [Ver en BaseScan](https://sepolia.basescan.org/address/0x2212FBb6C244267c23a5710E7e6c4769Ea423beE) |
| **MarketplaceCore** | `0x7fe5708061E76C271a1A9466f73D7667ed0C7Ddd` | [Ver en BaseScan](https://sepolia.basescan.org/address/0x7fe5708061E76C271a1A9466f73D7667ed0C7Ddd) |
| **DisputeResolution** | `0xD53df29C516D08e1F244Cb5912F0224Ea22B60E1` | [Ver en BaseScan](https://sepolia.basescan.org/address/0xD53df29C516D08e1F244Cb5912F0224Ea22B60E1) |
| **OracleRegistry** | `0x3Dd8A23983b94bC208D614C4325D937b710B6E4B` | [Ver en BaseScan](https://sepolia.basescan.org/address/0x3Dd8A23983b94bC208D614C4325D937b710B6E4B) |
| **ReferralSystem** | `0x747EEC46f064763726603c9C5fC928f99926a209` | [Ver en BaseScan](https://sepolia.basescan.org/address/0x747EEC46f064763726603c9C5fC928f99926a209) |

---

## 🔧 Configuración para Desarrollo

### JavaScript/TypeScript (Web)
```javascript
const KONEQUE_CONTRACTS = {
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
};

const CHAIN_CONFIG = {
  chainId: 84532,
  name: "Base Sepolia",
  rpcUrl: "https://sepolia.base.org",
  blockExplorer: "https://sepolia.basescan.org",
  nativeCurrency: {
    name: "Ethereum",
    symbol: "ETH",
    decimals: 18
  }
};
```

### Dart/Flutter (App)
```dart
class KonequeContracts {
  static const Map<String, String> addresses = {
    'MARKETPLACE_CORE': '0x7fe5708061E76C271a1A9466f73D7667ed0C7Ddd',
    'SMART_ACCOUNT_FACTORY': '0x030850c3DEa419bB1c76777F0C2A65c34FB60392',
    'REFERRAL_SYSTEM': '0x747EEC46f064763726603c9C5fC928f99926a209',
    'NATIVE_TOKEN': '0x697943EF354BFc7c12169D5303cbbB23b133dc53',
    'ESCROW': '0x8bbDDc3fcb74CdDB7050552b4DE01415C9966133',
    'FEE_MANAGER': '0x2212FBb6C244267c23a5710E7e6c4769Ea423beE',
    'PAYMASTER': '0x44b89ba09a381F3b598a184A90F039948913dC72',
    'DISPUTE_RESOLUTION': '0xD53df29C516D08e1F244Cb5912F0224Ea22B60E1',
    'ACCOUNT_FACTORY': '0x422478a088ce4d9D9418d4D2C9D99c78fC23393f',
    'SMART_ACCOUNT_IMPL': '0xf24e12Ef8aAcB99FC5843Fc56BEA0BFA5B039BFF',
    'ORACLE_REGISTRY': '0x3Dd8A23983b94bC208D614C4325D937b710B6E4B'
  };
  
  static const int chainId = 84532;
  static const String rpcUrl = 'https://sepolia.base.org';
  static const String blockExplorer = 'https://sepolia.basescan.org';
}
```

### Python (Scripts/Backend)
```python
KONEQUE_CONTRACTS = {
    "MARKETPLACE_CORE": "0x7fe5708061E76C271a1A9466f73D7667ed0C7Ddd",
    "SMART_ACCOUNT_FACTORY": "0x030850c3DEa419bB1c76777F0C2A65c34FB60392",
    "REFERRAL_SYSTEM": "0x747EEC46f064763726603c9C5fC928f99926a209",
    "NATIVE_TOKEN": "0x697943EF354BFc7c12169D5303cbbB23b133dc53",
    "ESCROW": "0x8bbDDc3fcb74CdDB7050552b4DE01415C9966133",
    "FEE_MANAGER": "0x2212FBb6C244267c23a5710E7e6c4769Ea423beE",
    "PAYMASTER": "0x44b89ba09a381F3b598a184A90F039948913dC72",
    "DISPUTE_RESOLUTION": "0xD53df29C516D08e1F244Cb5912F0224Ea22B60E1",
    "ACCOUNT_FACTORY": "0x422478a088ce4d9D9418d4D2C9D99c78fC23393f",
    "SMART_ACCOUNT_IMPL": "0xf24e12Ef8aAcB99FC5843Fc56BEA0BFA5B039BFF",
    "ORACLE_REGISTRY": "0x3Dd8A23983b94bC208D614C4325D937b710B6E4B"
}

CHAIN_CONFIG = {
    "chain_id": 84532,
    "name": "Base Sepolia",
    "rpc_url": "https://sepolia.base.org",
    "block_explorer": "https://sepolia.basescan.org"
}
```

---

## 📊 Información del Deployment

### Detalles de la Transacción
- **Fecha de Deployment**: 31 de agosto de 2025
- **Red**: Base Sepolia (Testnet)
- **Gas Usado**: ~15.6M gas total
- **Costo Total**: ~0.000015 ETH
- **Compiler**: Solidity 0.8.20
- **Optimizaciones**: 200 runs

### Estado de Verificación
✅ **Todos los contratos han sido verificados exitosamente en BaseScan**

### Funcionalidades Implementadas
- ✅ Sistema de Marketplace con 5 estados de transacción detallados
- ✅ Sistema de Referidos con códigos y expiración
- ✅ Account Abstraction (EIP-4337) con SmartAccount Factory
- ✅ Sistema de Escrow para transacciones seguras
- ✅ Gestión de comisiones y recompensas
- ✅ Sistema de resolución de disputas
- ✅ Paymaster para transacciones sin gas
- ✅ Registro de oráculos para validación externa

---

## 🔧 ABIs y Artifacts

Los ABIs compilados están disponibles en:
- `out/` - Directorio de artifacts de Foundry
- `broadcast/` - Historial de transacciones de deployment

Para uso en frontend, copiar los ABIs desde:
```bash
# Copiar ABIs para uso en JavaScript/TypeScript
cp out/MarketplaceCore.sol/MarketplaceCore.json frontend/src/abis/
cp out/SmartAccountFactory.sol/SmartAccountFactory.json frontend/src/abis/
cp out/ReferralSystem.sol/ReferralSystem.json frontend/src/abis/
cp out/NativeToken.sol/NativeToken.json frontend/src/abis/

# Para Flutter
cp out/MarketplaceCore.sol/MarketplaceCore.json flutter_app/assets/abis/
cp out/SmartAccountFactory.sol/SmartAccountFactory.json flutter_app/assets/abis/
cp out/ReferralSystem.sol/ReferralSystem.json flutter_app/assets/abis/
cp out/NativeToken.sol/NativeToken.json flutter_app/assets/abis/
```

---

## 🧪 Testing

Para interactuar con los contratos en testnet:

1. **Obtener tokens de prueba**:
   - ETH en Base Sepolia: [Faucet de Base](https://portal.cdp.coinbase.com/products/faucet)
   - KNQ tokens: Interactuar con `NativeToken` contract

2. **URLs útiles**:
   - RPC: `https://sepolia.base.org`
   - Chain ID: `84532`
   - Explorer: `https://sepolia.basescan.org`

3. **Wallet Configuration**:
   - Network Name: Base Sepolia
   - RPC URL: https://sepolia.base.org
   - Chain ID: 84532
   - Currency Symbol: ETH
   - Block Explorer: https://sepolia.basescan.org

---

**📋 Estado**: ✅ Todos los contratos deployados y verificados exitosamente
**🔄 Última actualización**: 31 de agosto de 2025
**📞 Soporte**: Consultar documentación técnica en `/docs`
