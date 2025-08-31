# 📑 Documentación de la Arquitectura de Contratos del Marketplace Descentralizado

## 🔹 1. Account Abstraction Layer

### **AccountFactory**
Factory responsable de desplegar Smart Accounts usando CREATE2 para cuentas determinísticas.

**Métodos:**
- `createAccount(owner, salt)`: Despliega una nueva SmartAccount con dirección determinística
- `getAccountAddress(owner, salt)`: Calcula la dirección de cuenta antes del despliegue
- `isAccountDeployed(account)`: Verifica si una cuenta ya fue desplegada

### **SmartAccount**
Cuenta abstracta (EIP-4337) que sustituye a las cuentas EOA tradicionales.

**Métodos:**
- `execute(target, value, data)`: Ejecuta una transacción única
- `executeBatch(targets[], values[], datas[])`: Ejecuta múltiples transacciones en una sola operación
- `validateUserOp(userOp)`: Valida operaciones de usuario según EIP-4337
- `addOwner(newOwner)`: Agrega un nuevo propietario (multisig)
- `removeOwner(owner)`: Remueve un propietario existente
- `setGuardian(guardian)`: Establece guardián para recuperación social

### **Paymaster**
Contrato EIP-4337 que paga el gas en nombre de las SmartAccounts usando tokens nativos.

**Métodos:**
- `validatePaymasterUserOp(userOp)`: Valida y acepta pagar gas por la operación
- `postOp(context, actualGasCost)`: Ejecuta lógica post-operación para cobrar tokens
- `depositFor(account)`: Permite depósitos de tokens para cubrir gas futuro
- `withdrawTo(recipient, amount)`: Retira tokens depositados

## 🔹 2. Marketplace Layer

### **MarketplaceCore**
Contrato principal que maneja la lógica de compraventa del marketplace.

**Métodos:**
- `listItem(price, metadataURI, category)`: Lista un producto para venta
- `buyItem(itemId)`: Compra un producto individual
- `buyBatch(itemIds[])`: Compra múltiples productos en una transacción
- `cancelListing(itemId)`: Cancela un listado activo
- `confirmDelivery(transactionId)`: Comprador confirma recepción del producto
- `getItemDetails(itemId)`: Obtiene información detallada de un producto
- `getActiveListings()`: Retorna todos los productos activos

### **Escrow**
Custodia segura de fondos durante las transacciones hasta su finalización o resolución de disputas.

**Métodos:**
- `lockFunds(transactionId, buyer, seller, amount)`: Bloquea fondos al iniciar compra
- `releaseFunds(transactionId)`: Libera fondos al vendedor tras confirmación
- `refundBuyer(transactionId)`: Devuelve fondos al comprador en caso de disputa favorable
- `getEscrowBalance(transactionId)`: Consulta fondos bloqueados para una transacción
- `getEscrowStatus(transactionId)`: Obtiene el estado actual del escrow

### **FeeManager**
Gestiona el procesamiento y distribución de todas las comisiones del sistema.

**Métodos:**
- `calculateFees(amount, feeType)`: Calcula comisiones según tipo de transacción
- `distributeFees(transactionId, totalFees)`: Distribuye comisiones entre referidos y plataforma
- `setFeeRate(feeType, newRate)`: Actualiza tasas de comisión
- `collectPlatformFees()`: Recauda comisiones acumuladas de la plataforma
- `processReferralReward(referrer, amount)`: Procesa recompensa de referido

## 🔹 3. Dispute & Oracle Layer

### **DisputeResolution**
Administra conflictos entre compradores y vendedores a través de oráculos humanos.

**Métodos:**
- `raiseDispute(transactionId, reason)`: Inicia una disputa sobre una transacción
- `submitEvidence(transactionId, evidenceURI)`: Envía evidencia para la disputa
- `assignOracles(transactionId)`: Asigna oráculos aleatorios para resolver disputa
- `submitVerdict(transactionId, decision, reasoning)`: Oráculos envían su veredicto
- `finalizeDispute(transactionId)`: Finaliza disputa y ejecuta veredicto mayoritario
- `getDisputeDetails(transactionId)`: Obtiene información completa de la disputa

### **OracleRegistry**
Registra y administra oráculos humanos que resuelven disputas con sistema de reputación.

**Métodos:**
- `registerOracle(stake)`: Registra nuevo oráculo con stake mínimo
- `updateReputation(oracle, performance)`: Actualiza reputación basada en desempeño
- `selectOracles(transactionId, count)`: Selecciona oráculos aleatorios ponderados por reputación
- `slashOracle(oracle, amount)`: Penaliza oráculo por decisión deshonesta
- `rewardOracle(oracle, amount)`: Recompensa oráculo por decisión correcta
- `getOracleStats(oracle)`: Obtiene estadísticas de desempeño del oráculo

## 🔹 4. Incentive Layer

### **ReferralSystem**
Gestiona el sistema de referidos y recompensas por crecimiento de usuarios.

**Métodos:**
- `registerReferral(referrer, referred)`: Registra relación referidor-referido
- `claimReferralReward(referred)`: Reclama recompensa cuando referido completa primera compra
- `setReferralRate(newRate)`: Actualiza porcentaje de recompensa por referido
- `getReferralStats(referrer)`: Obtiene estadísticas de referidos de un usuario
- `validateReferralEligibility(referred)`: Verifica elegibilidad para recompensa

## 🔹 5. Token Layer

### **NativeToken**
Token ERC-20 nativo del marketplace usado para gas, recompensas y gobernanza futura.

**Métodos:**
- `mint(to, amount)`: Acuña tokens (solo owner/governance)
- `burn(amount)`: Quema tokens del balance propio
- `transfer(to, amount)`: Transfiere tokens estándar ERC-20
- `approve(spender, amount)`: Aprueba gasto de tokens
- `stake(amount, duration)`: Permite hacer staking para beneficios adicionales

---

## 🔹 6. Flujos de Operación

### **Flujo de Listado de Producto**
1. Vendedor llama `MarketplaceCore.listItem(price, metadataURI, category)`
2. `FeeManager.calculateFees()` calcula comisión de listado
3. `Paymaster` cubre gas de la transacción usando tokens nativos
4. Producto queda activo y visible en el marketplace

### **Flujo de Compra**
1. Comprador selecciona producto(s) y llama `MarketplaceCore.buyItem()` o `buyBatch()`
2. `FeeManager.calculateFees()` calcula comisiones totales (marketplace + referido)
3. `Escrow.lockFunds()` bloquea fondos del comprador
4. `FeeManager.distributeFees()` distribuye comisiones apropiadas
5. `Paymaster` cubre gas usando tokens nativos del comprador
6. Producto(s) marcado como vendido, fondos en escrow hasta confirmación

### **Flujo de Confirmación de Entrega**
1. Comprador recibe producto y llama `MarketplaceCore.confirmDelivery()`
2. `Escrow.releaseFunds()` libera fondos al vendedor
3. Transacción completada exitosamente

### **Flujo de Disputa**
1. Comprador o vendedor llama `DisputeResolution.raiseDispute(transactionId, reason)`
2. `OracleRegistry.selectOracles()` asigna 3-5 oráculos aleatorios ponderados por reputación
3. Partes envían evidencia con `submitEvidence(transactionId, evidenceURI)`
4. Oráculos revisan evidencia y llaman `submitVerdict(transactionId, decision, reasoning)`
5. `DisputeResolution.finalizeDispute()` ejecuta veredicto mayoritario:
   - Si favorece comprador: `Escrow.refundBuyer()`
   - Si favorece vendedor: `Escrow.releaseFunds()`
6. `OracleRegistry` actualiza reputación y distribuye recompensas/penalizaciones

### **Flujo de Resolución con Oráculos**
1. Oráculos reciben notificación de nueva disputa
2. Revisan evidencia presentada por ambas partes
3. Analizan términos de la transacción y políticas del marketplace
4. Envían veredicto fundamentado dentro del plazo establecido
5. Sistema ejecuta automáticamente decisión mayoritaria
6. Oráculos honestos reciben recompensa en tokens nativos
7. Oráculos deshonestos (minoría) sufren penalización (slashing) parcial de su stake

---
