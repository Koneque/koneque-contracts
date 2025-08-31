# 🚀 Koneque Contracts - Deployment Documentation

## 📋 Información General

**Red:** Base Sepolia Testnet  
**Chain ID:** 84532  
**Fecha de Deploy:** 31 de agosto de 2025  
**Deployer:** [Tu dirección]  
**Costo Total:** ~0.000015 ETH  

---

## 📜 Contratos Desplegados

### 🪙 Token Nativo
**NativeToken**
- **Dirección:** `0x3422820Ef9FBC8e0206E4CBcB6369dBd14BE18c4`
- **Descripción:** Token ERC-20 nativo de la plataforma Koneque
- **Funcionalidades:**
  - Minteo de tokens
  - Transferencias estándar ERC-20
  - Sistema de allowances
  - Quema de tokens (burn)

### 👤 Sistema de Cuentas

**SmartAccount Implementation**
- **Dirección:** `0x5B02258b1441F2850a45eb7949d83f6B103e731e`
- **Descripción:** Implementación de cuenta inteligente compatible con ERC-4337
- **Funcionalidades:**
  - Account Abstraction
  - Ejecución de transacciones por lotes
  - Gestión de permisos

**AccountFactory**
- **Dirección:** `0x5f7272c1532b6B05558757AAC74e4D21E58DECAe`
- **Descripción:** Factory para crear nuevas cuentas inteligentes
- **Funcionalidades:**
  - Creación determinística de cuentas
  - Gestión de implementaciones
  - Registro de cuentas creadas

**Paymaster**
- **Dirección:** `0x5FCA60cbb22e38F8172ae6BA41FFCfad007a41BD`
- **Descripción:** Contrato para patrocinar gas fees
- **Funcionalidades:**
  - Pago de gas fees por usuarios
  - Gestión de fondos para sponsorship
  - Validación de transacciones sponsoreadas

### 🏪 Sistema de Marketplace

**MarketplaceCore**
- **Dirección:** `0xbB4fE95d722457484Bc42453d5346a166C7bCAE9`
- **Descripción:** Contrato principal del marketplace
- **Funcionalidades:**
  - Creación y gestión de órdenes
  - Matching de compradores y vendedores
  - Gestión de estados de transacciones
  - Integración con escrow y fees

**Escrow**
- **Dirección:** `0xdE0E60DCaf3e8b36F3C92a9Ea6D97C0e9a3ca194`
- **Descripción:** Sistema de custodia de fondos
- **Funcionalidades:**
  - Bloqueo seguro de fondos
  - Liberación automática y manual
  - Gestión de disputas
  - Reembolsos y cancelaciones

**FeeManager**
- **Dirección:** `0x4EF6c34dEEae92d4a6314Ba0C0C76fBe1E8360D0`
- **Descripción:** Gestión de comisiones de la plataforma
- **Funcionalidades:**
  - Cálculo de fees dinámicos
  - Distribución de comisiones
  - Gestión de descuentos por referidos
  - Configuración de tarifas

### ⚖️ Sistema de Disputas

**DisputeResolution**
- **Dirección:** `0x4A1E9765473e4E29EB77250360622c6251D2D4e1`
- **Descripción:** Sistema de resolución de disputas
- **Funcionalidades:**
  - Creación de disputas
  - Asignación de árbitros
  - Votación y resolución
  - Ejecución de decisiones

**OracleRegistry**
- **Dirección:** `0xA6680F13c455655C458807C96AEf1947E87572B2`
- **Descripción:** Registro de oráculos y árbitros
- **Funcionalidades:**
  - Registro de oráculos verificados
  - Gestión de reputación
  - Asignación aleatoria de árbitros
  - Stake de garantía

### 🎁 Sistema de Incentivos

**ReferralSystem**
- **Dirección:** `0xB0EBE476289D5070E18Fb7e4C6F44Ce97Be30211`
- **Descripción:** Sistema de referidos y recompensas
- **Funcionalidades:**
  - Gestión de códigos de referido
  - Tracking de conversiones
  - Distribución de recompensas
  - Programa de afiliados

---

## 🔗 Relaciones Entre Contratos

### Configuraciones Principales:

1. **MarketplaceCore** se conecta con:
   - Escrow para custodia de fondos
   - FeeManager para gestión de comisiones

2. **Escrow** se integra con:
   - MarketplaceCore para órdenes
   - DisputeResolution para disputas

3. **FeeManager** trabaja con:
   - MarketplaceCore para transacciones
   - ReferralSystem para descuentos

4. **DisputeResolution** utiliza:
   - OracleRegistry para árbitros
   - Escrow para ejecución de decisiones
   - MarketplaceCore para contexto

5. **ReferralSystem** se conecta con:
   - FeeManager para aplicar descuentos
   - MarketplaceCore para tracking

---

## 🛠️ Configuración Técnica

### Variables de Entorno Utilizadas:
```bash
BASE_SEPOLIA_RPC_URL="https://sepolia.base.org"
PRIVATE_KEY=0xf1f0b805524fea3b1f028732baa9c50380cff58a9ec048cb20f039888fd8626d
```

### Comando de Deploy:
```bash
source .env && forge script script/Deploy.s.sol:DeployScript --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast
```

### Archivos de Logs:
- **Transacciones:** `broadcast/Deploy.s.sol/84532/run-latest.json`
- **Cache:** `cache/Deploy.s.sol/84532/run-latest.json`

---

## 🔍 Verificación de Contratos

Para verificar los contratos en el explorador de Base Sepolia:

1. Visita: https://sepolia.basescan.org/
2. Busca cada dirección de contrato
3. Los contratos fueron desplegados en el bloque ~30431731-30431732

### Enlaces Directos:

- [NativeToken](https://sepolia.basescan.org/address/0x3422820Ef9FBC8e0206E4CBcB6369dBd14BE18c4)
- [MarketplaceCore](https://sepolia.basescan.org/address/0xbB4fE95d722457484Bc42453d5346a166C7bCAE9)
- [Escrow](https://sepolia.basescan.org/address/0xdE0E60DCaf3e8b36F3C92a9Ea6D97C0e9a3ca194)
- [FeeManager](https://sepolia.basescan.org/address/0x4EF6c34dEEae92d4a6314Ba0C0C76fBe1E8360D0)

---

## 🧪 Testing y Interacción

### Interacción Básica:

1. **Mint tokens de prueba:**
   ```bash
   cast send 0x3422820Ef9FBC8e0206E4CBcB6369dBd14BE18c4 "mint(address,uint256)" [TU_DIRECCION] 1000000000000000000000 --rpc-url $BASE_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
   ```

2. **Verificar balance:**
   ```bash
   cast call 0x3422820Ef9FBC8e0206E4CBcB6369dBd14BE18c4 "balanceOf(address)" [TU_DIRECCION] --rpc-url $BASE_SEPOLIA_RPC_URL
   ```

3. **Crear cuenta inteligente:**
   ```bash
   cast send 0x5f7272c1532b6B05558757AAC74e4D21E58DECAe "createAccount(address,uint256)" [OWNER] [SALT] --rpc-url $BASE_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
   ```

---

## 📝 Notas Importantes

### ⚠️ Consideraciones de Seguridad:
- Los contratos están desplegados en testnet
- La private key mostrada es de ejemplo y debe ser reemplazada
- Todos los contratos han sido configurados con las relaciones necesarias
- El deployer tiene permisos administrativos iniciales

### 🔄 Próximos Pasos:
1. Verificar contratos en el explorador
2. Configurar frontend con las direcciones
3. Ejecutar tests de integración
4. Documentar APIs y funciones públicas
5. Preparar para mainnet

### 📞 Soporte:
- Repositorio: https://github.com/Koneque/koneque-contracts
- Chain: Base Sepolia (84532)
- Explorador: https://sepolia.basescan.org/

---

*Documentación generada automáticamente el 31 de agosto de 2025*
