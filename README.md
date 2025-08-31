# Koneque Marketplace - Smart Contracts

Koneque es un marketplace descentralizado construido en Ethereum que implementa Account Abstraction (EIP-4337), resolución de disputas descentralizada con oráculos humanos, y un sistema completo de incentivos.

## 🏗️ Arquitectura

### Capa de Account Abstraction
- **AccountFactory**: Factory para crear Smart Accounts determinísticas
- **SmartAccount**: Cuentas abstractas con soporte multi-firma y recuperación social
- **Paymaster**: Permite pagar gas con tokens nativos en lugar de ETH

### Capa de Marketplace
- **MarketplaceCore**: Lógica principal de compraventa
- **Escrow**: Custodia segura de fondos durante transacciones
- **FeeManager**: Gestión y distribución de comisiones

### Capa de Disputas y Oráculos
- **DisputeResolution**: Administra conflictos entre compradores y vendedores
- **OracleRegistry**: Registro y gestión de oráculos humanos con sistema de reputación

### Capa de Incentivos
- **ReferralSystem**: Sistema de referidos con recompensas

### Capa de Token
- **NativeToken**: Token ERC-20 nativo con funcionalidades de staking

## 🚀 Características Principales

### ✅ Account Abstraction (EIP-4337)
- Cuentas determinísticas con CREATE2
- Multi-firma y recuperación social
- Gas patrocinado con tokens nativos
- Operaciones por lotes

### ✅ Marketplace Descentralizado
- Listado y compra de productos
- Compras por lotes
- Escrow automático de fondos
- Confirmación de entrega

### ✅ Resolución de Disputas
- Oráculos humanos con stake
- Sistema de reputación
- Votación mayoría ponderada
- Recompensas y penalizaciones automáticas

### ✅ Sistema de Incentivos
- Referidos con recompensas automáticas
- Staking de tokens con rewards
- Comisiones distribuidas automáticamente

## 📁 Estructura del Proyecto

```
src/
├── account/
│   ├── AccountFactory.sol
│   ├── SmartAccount.sol
│   └── Paymaster.sol
├── marketplace/
│   ├── MarketplaceCore.sol
│   ├── Escrow.sol
│   └── FeeManager.sol
├── dispute/
│   ├── DisputeResolution.sol
│   └── OracleRegistry.sol
├── incentives/
│   └── ReferralSystem.sol
├── token/
│   └── NativeToken.sol
└── interfaces/
    ├── IAccount.sol
    ├── IMarketplace.sol
    ├── IDispute.sol
    └── IReferral.sol
```

## 🛠️ Instalación y Configuración

### Prerrequisitos
- [Foundry](https://getfoundry.sh/)
- Node.js >= 16
- Git

### Instalación
```bash
git clone <repository-url>
cd koneque-contracts
forge install
```

### Compilación
```bash
forge build
```

### Tests
```bash
# Tests unitarios
forge test --match-path "test/unit/**"

# Tests de integración
forge test --match-path "test/integration/**"

# Todos los tests
forge test

# Tests con verbosidad
forge test -vvv
```

## 🚀 Despliegue

### Red Local
```bash
# Iniciar nodo local
anvil

# Desplegar contratos
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY --broadcast
```

### Testnet/Mainnet
```bash
# Configurar variables de entorno
export PRIVATE_KEY=0xyour_private_key
export RPC_URL=your_rpc_url

# Desplegar en Base Sepolia
source .env && forge script script/Deploy.s.sol:DeployScript --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast
```

### 📋 Contratos Desplegados

El proyecto está actualmente desplegado en **Base Sepolia**. Para información detallada sobre las direcciones y configuración:

- 📄 **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Documentación completa de deployment
- 📊 **[contracts.json](./contracts.json)** - Direcciones en formato JSON
- 🔧 **[contracts.ts](./contracts.ts)** - Configuración para TypeScript/JavaScript
- ⚡ **[interact.sh](./interact.sh)** - Script de interacción rápida

#### Interacción Rápida
```bash
# Mostrar información de deployment
./interact.sh info

# Verificar estado de contratos
./interact.sh check

# Mint tokens de prueba
./interact.sh mint <address> <amount>

# Crear cuenta inteligente
./interact.sh create-account <owner_address>
```

## 📊 Flujos de Operación

### Flujo de Listado
1. Vendedor llama `MarketplaceCore.listItem()`
2. `FeeManager` calcula comisión de listado
3. `Paymaster` cubre gas usando tokens nativos
4. Producto activo en marketplace

### Flujo de Compra
1. Comprador selecciona producto(s)
2. `FeeManager` calcula comisiones totales
3. `Escrow` bloquea fondos del comprador
4. Distribución automática de comisiones
5. Producto marcado como vendido

### Flujo de Disputa
1. Parte inicia disputa con `raiseDispute()`
2. `OracleRegistry` asigna oráculos aleatorios
3. Partes envían evidencia
4. Oráculos votan con fundamentos
5. Ejecución automática de veredicto mayoritario
6. Actualización de reputaciones y recompensas

## 🔧 Configuración de Contratos

Después del despliegue, los contratos necesitan ser configurados:

```solidity
// Configurar marketplace
marketplaceCore.setEscrowContract(escrowAddress);
marketplaceCore.setFeeManager(feeManagerAddress);

// Configurar escrow
escrow.setMarketplaceCore(marketplaceCoreAddress);
escrow.setDisputeResolution(disputeResolutionAddress);

// Configurar dispute resolution
disputeResolution.setOracleRegistry(oracleRegistryAddress);
// ... más configuraciones
```

## 🧪 Testing

### Tests Unitarios
- `NativeToken.t.sol`: Funcionalidades del token nativo
- `Marketplace.t.sol`: Lógica de marketplace
- Más tests en `test/unit/`

### Tests de Integración
- `FullFlow.t.sol`: Flujo completo del marketplace
- Tests de disputas end-to-end
- Tests de account abstraction

### Coverage
```bash
forge coverage
```

## 🔐 Seguridad

### Características de Seguridad
- ReentrancyGuard en todas las funciones críticas
- AccessControl para permisos granulares
- Pausable para emergencias
- Límites de tiempo en disputas
- Validación exhaustiva de inputs

### Auditorías
- [ ] Auditoría de seguridad pendiente
- [ ] Tests de fuzzing
- [ ] Análisis estático con Slither

## 📜 Licencia

MIT License

## 🤝 Contribución

1. Fork el proyecto
2. Crea tu rama de feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📞 Contacto

- Proyecto: Koneque Marketplace
- Documentación: Ver `arquitectura.md`
- Issues: GitHub Issues
