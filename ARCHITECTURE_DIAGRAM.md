# Diagrama de Flujo - Sistema Koneque Marketplace

## 📋 Arquitectura General del Sistema

```mermaid
graph TB
    %% User Layer
    subgraph "👥 Capa de Usuario"
        USER[👤 Usuario]
        SELLER[🏪 Vendedor]
        BUYER[🛒 Comprador]
        REFERRER[🤝 Referidor]
    end

    %% Account Abstraction Layer
    subgraph "🔐 Account Abstraction (EIP-4337)"
        SA[SmartAccount<br/>Cuentas Inteligentes]
        PM[Paymaster<br/>Patrocinador de Gas]
        EP[EntryPoint<br/>Punto de Entrada]
    end

    %% Core Contracts
    subgraph "🏛️ Contratos Principales"
        MC[MarketplaceCore<br/>Núcleo del Marketplace]
        ESC[Escrow<br/>Custodia de Fondos]
        FM[FeeManager<br/>Gestor de Comisiones]
        RS[ReferralSystem<br/>Sistema de Referidos]
    end

    %% Support Contracts
    subgraph "🛠️ Contratos de Soporte"
        DR[DisputeResolution<br/>Resolución de Disputas]
        OR[OracleRegistry<br/>Registro de Oráculos]
        NT[NativeToken<br/>Token Nativo]
    end

    %% External Systems
    subgraph "🌐 Sistemas Externos"
        ORACLE1[🔮 Oráculo 1]
        ORACLE2[🔮 Oráculo 2]
        ORACLE3[🔮 Oráculo 3]
    end

    %% User Interactions
    USER --> SA
    SELLER --> SA
    BUYER --> SA
    REFERRER --> SA

    %% Account Abstraction Flow
    SA --> EP
    PM --> EP
    EP --> MC

    %% Core Contract Interactions
    MC --> ESC
    MC --> FM
    MC --> RS
    ESC --> DR
    FM --> RS
    DR --> OR

    %% Oracle Interactions
    OR --> ORACLE1
    OR --> ORACLE2
    OR --> ORACLE3

    %% Token Interactions
    ESC --> NT
    FM --> NT
    RS --> NT

    %% Styling
    classDef userClass fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef accountClass fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef coreClass fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    classDef supportClass fill:#fff3e0,stroke:#ef6c00,stroke-width:2px
    classDef externalClass fill:#fce4ec,stroke:#c2185b,stroke-width:2px

    class USER,SELLER,BUYER,REFERRER userClass
    class SA,PM,EP accountClass
    class MC,ESC,FM,RS coreClass
    class DR,OR,NT supportClass
    class ORACLE1,ORACLE2,ORACLE3 externalClass
```

## 🔄 Flujo de Transacciones

```mermaid
sequenceDiagram
    participant U as 👤 Usuario
    participant SA as 🔐 SmartAccount
    participant MC as 🏪 MarketplaceCore
    participant ESC as 💰 Escrow
    participant FM as 💳 FeeManager
    participant RS as 🤝 ReferralSystem
    participant NT as 🪙 NativeToken

    Note over U,NT: 📝 Listado de Producto
    U->>SA: Crear producto
    SA->>MC: listItem(precio, metadata, categoría)
    MC->>MC: Crear Item con ID único
    MC-->>SA: itemId
    SA-->>U: ✅ Producto listado

    Note over U,NT: 🛒 Compra de Producto
    U->>SA: Comprar producto
    SA->>NT: Aprobar tokens
    SA->>MC: buyItem(itemId)
    MC->>ESC: lockFunds(transactionId, buyer, seller, amount)
    MC->>FM: calculateFees(transactionId, amount)
    MC->>RS: recordFirstPurchase(buyer, amount)
    MC-->>SA: transactionId
    SA-->>U: ✅ Compra realizada (PAYMENT_COMPLETED)

    Note over U,NT: 📦 Confirmación de Entrega
    U->>SA: Confirmar entrega
    SA->>MC: confirmDelivery(transactionId)
    MC->>MC: status = PRODUCT_DELIVERED
    MC-->>SA: ✅ Entrega confirmada
    SA-->>U: Producto marcado como entregado

    Note over U,NT: ✅ Finalización de Transacción
    U->>SA: Finalizar transacción
    SA->>MC: finalizeTransaction(transactionId)
    MC->>ESC: releaseFunds(transactionId)
    ESC->>FM: distributeFees(transactionId)
    FM->>NT: Transferir comisiones
    FM->>RS: processReferralReward(buyer)
    MC->>MC: status = FINALIZED
    MC-->>SA: ✅ Transacción finalizada
    SA-->>U: Fondos liberados al vendedor
```

## 🤝 Flujo del Sistema de Referidos

```mermaid
flowchart TD
    START([🚀 Inicio]) --> CREATE_CODE{👤 ¿Crear código de referido?}
    
    CREATE_CODE -->|Sí| RC[📝 Crear Código de Referido<br/>createReferralCode]
    RC --> VALIDATE_CODE[✅ Validar código único<br/>y parámetros]
    VALIDATE_CODE --> STORE_CODE[💾 Almacenar código<br/>con expiración]
    
    CREATE_CODE -->|No| USE_CODE{🔗 ¿Usar código existente?}
    USE_CODE -->|Sí| CHECK_CODE[🔍 Verificar código<br/>isReferralCodeValid]
    CHECK_CODE --> VALID{✅ ¿Código válido?}
    
    VALID -->|No| ERROR_EXPIRED[❌ Error: Código expirado<br/>o inválido]
    VALID -->|Sí| REGISTER[📋 Registrar referido<br/>registerReferralWithCode]
    
    REGISTER --> CHECK_PURCHASE{🛒 ¿Primera compra?}
    CHECK_PURCHASE -->|Sí| RECORD_PURCHASE[💰 Registrar compra<br/>recordFirstPurchase]
    RECORD_PURCHASE --> ELIGIBLE[🎁 Elegible para recompensa]
    
    CHECK_PURCHASE -->|No| WAIT_PURCHASE[⏳ Esperar primera compra]
    WAIT_PURCHASE --> CHECK_EXPIRY{📅 ¿Referido expirado?}
    
    CHECK_EXPIRY -->|Sí| EXPIRED[❌ Referido expirado<br/>90 días]
    CHECK_EXPIRY -->|No| RECORD_PURCHASE
    
    ELIGIBLE --> CLAIM_REWARD[🏆 Reclamar recompensa<br/>claimReferralReward]
    CLAIM_REWARD --> DISTRIBUTE[💸 Distribuir tokens<br/>al referidor]
    
    STORE_CODE --> END([🏁 Fin])
    USE_CODE -->|No| END
    ERROR_EXPIRED --> END
    EXPIRED --> END
    DISTRIBUTE --> END

    %% Styling
    classDef processClass fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    classDef decisionClass fill:#fff3e0,stroke:#ef6c00,stroke-width:2px
    classDef errorClass fill:#ffebee,stroke:#c62828,stroke-width:2px
    classDef successClass fill:#e1f5fe,stroke:#01579b,stroke-width:2px

    class RC,VALIDATE_CODE,STORE_CODE,CHECK_CODE,REGISTER,RECORD_PURCHASE,CLAIM_REWARD,DISTRIBUTE processClass
    class CREATE_CODE,USE_CODE,VALID,CHECK_PURCHASE,CHECK_EXPIRY decisionClass
    class ERROR_EXPIRED,EXPIRED errorClass
    class ELIGIBLE,END successClass
```

## 🏛️ Estados de Transacciones

```mermaid
stateDiagram-v2
    [*] --> PAYMENT_COMPLETED : buyItem() ✅

    PAYMENT_COMPLETED --> PRODUCT_DELIVERED : confirmDelivery() 📦
    PAYMENT_COMPLETED --> IN_DISPUTE : initiateDispute() ⚖️

    PRODUCT_DELIVERED --> FINALIZED : finalizeTransaction() ✅
    PRODUCT_DELIVERED --> IN_DISPUTE : initiateDispute() ⚖️

    IN_DISPUTE --> REFUNDED : refundTransaction() 💰
    IN_DISPUTE --> FINALIZED : resolveDispute() ✅

    FINALIZED --> [*] : Transacción Completa 🎉
    REFUNDED --> [*] : Fondos Devueltos 💸

    note right of PAYMENT_COMPLETED
        🔒 Fondos bloqueados en Escrow
        Producto listado como vendido
    end note

    note right of PRODUCT_DELIVERED
        📦 Comprador confirma recepción
        Listo para finalización
    end note

    note right of IN_DISPUTE
        ⚖️ Proceso de resolución activado
        Oráculos pueden intervenir
    end note

    note right of FINALIZED
        ✅ Fondos liberados al vendedor
        Comisiones distribuidas
        Recompensas de referido procesadas
    end note

    note right of REFUNDED
        💰 Fondos devueltos al comprador
        Transacción cancelada
    end note
```

## 🔧 Arquitectura de Contratos

```mermaid
graph LR
    subgraph "🎯 Frontend Layer"
        DAPP[📱 DApp Interface]
        WALLET[👛 Wallet Connection]
    end

    subgraph "🔐 Account Abstraction"
        SA[SmartAccount]
        PM[Paymaster]
        EP[EntryPoint]
    end

    subgraph "🏪 Marketplace Core"
        MC[MarketplaceCore<br/>- listItem()<br/>- buyItem()<br/>- confirmDelivery()<br/>- finalizeTransaction()]
        
        subgraph "💰 Financial Layer"
            ESC[Escrow<br/>- lockFunds()<br/>- releaseFunds()<br/>- Emergency functions]
            FM[FeeManager<br/>- calculateFees()<br/>- distributeFees()<br/>- Platform fees]
        end
        
        subgraph "🤝 Incentives Layer"
            RS[ReferralSystem<br/>- createReferralCode()<br/>- registerReferralWithCode()<br/>- claimReferralReward()]
        end
    end

    subgraph "⚖️ Governance Layer"
        DR[DisputeResolution<br/>- createDispute()<br/>- resolveDispute()<br/>- Oracle voting]
        OR[OracleRegistry<br/>- registerOracle()<br/>- Stake management<br/>- Reputation system]
    end

    subgraph "🪙 Token Layer"
        NT[NativeToken<br/>- ERC20 + Staking<br/>- Mint/Burn<br/>- Rewards distribution]
    end

    %% Frontend connections
    DAPP --> WALLET
    WALLET --> SA

    %% Account Abstraction flow
    SA --> EP
    PM --> EP
    EP --> MC

    %% Core marketplace connections
    MC --> ESC
    MC --> FM
    MC --> RS

    %% Financial layer connections
    ESC --> FM
    ESC --> DR
    FM --> RS

    %% Governance connections
    DR --> OR
    OR --> NT

    %% Token connections
    ESC --> NT
    FM --> NT
    RS --> NT

    %% Styling
    classDef frontendClass fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef accountClass fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef coreClass fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef financialClass fill:#fff8e1,stroke:#f57c00,stroke-width:2px
    classDef incentiveClass fill:#e0f2f1,stroke:#00695c,stroke-width:2px
    classDef governanceClass fill:#fce4ec,stroke:#ad1457,stroke-width:2px
    classDef tokenClass fill:#f1f8e9,stroke:#558b2f,stroke-width:2px

    class DAPP,WALLET frontendClass
    class SA,PM,EP accountClass
    class MC coreClass
    class ESC,FM financialClass
    class RS incentiveClass
    class DR,OR governanceClass
    class NT tokenClass
```

## 📊 Flujo de Datos y Eventos

```mermaid
graph TB
    subgraph "📡 Eventos del Sistema"
        E1[ItemListed 📝]
        E2[ItemPurchased 🛒]
        E3[DeliveryConfirmed 📦]
        E4[TransactionFinalized ✅]
        E5[TransactionDisputed ⚖️]
        E6[ReferralRegistered 🤝]
        E7[ReferralRewardClaimed 🎁]
        E8[DisputeCreated 🚨]
        E9[DisputeResolved 🏛️]
    end

    subgraph "💾 Estado del Sistema"
        ITEMS[Items Storage<br/>- ID, precio, metadata<br/>- Estado activo/inactivo]
        TRANSACTIONS[Transactions Storage<br/>- Estados detallados<br/>- Participantes<br/>- Montos]
        REFERRALS[Referrals Storage<br/>- Códigos y expiraciones<br/>- Relaciones referido-referidor<br/>- Recompensas pendientes]
        DISPUTES[Disputes Storage<br/>- Estado de disputas<br/>- Votos de oráculos<br/>- Resoluciones]
        ESCROWS[Escrow Storage<br/>- Fondos bloqueados<br/>- Estados de liberación]
    end

    subgraph "🔍 Consultas y Vistas"
        Q1[getActiveListings 📋]
        Q2[getTransactionsByStatus 📊]
        Q3[getReferralStats 📈]
        Q4[getPendingReward 💰]
        Q5[getDisputeDetails ⚖️]
        Q6[getOracleReputation 🏆]
    end

    %% Event flows
    E1 --> ITEMS
    E2 --> TRANSACTIONS
    E2 --> ESCROWS
    E3 --> TRANSACTIONS
    E4 --> TRANSACTIONS
    E4 --> ESCROWS
    E5 --> DISPUTES
    E6 --> REFERRALS
    E7 --> REFERRALS
    E8 --> DISPUTES
    E9 --> DISPUTES

    %% Query flows
    ITEMS --> Q1
    TRANSACTIONS --> Q2
    REFERRALS --> Q3
    REFERRALS --> Q4
    DISPUTES --> Q5
    DISPUTES --> Q6

    %% Styling
    classDef eventClass fill:#e8eaf6,stroke:#3f51b5,stroke-width:2px
    classDef storageClass fill:#f3e5f5,stroke:#9c27b0,stroke-width:2px
    classDef queryClass fill:#e0f2f1,stroke:#4caf50,stroke-width:2px

    class E1,E2,E3,E4,E5,E6,E7,E8,E9 eventClass
    class ITEMS,TRANSACTIONS,REFERRALS,DISPUTES,ESCROWS storageClass
    class Q1,Q2,Q3,Q4,Q5,Q6 queryClass
```

## 🛡️ Seguridad y Control de Acceso

```mermaid
graph TD
    subgraph "👑 Roles de Administración"
        OWNER[Owner<br/>🔑 Control total del sistema]
        MARKETPLACE[MarketplaceCore<br/>🏪 Operaciones principales]
        ESCROW_ROLE[Escrow<br/>💰 Gestión de fondos]
    end

    subgraph "🔒 Controles de Acceso"
        MOD1[onlyOwner<br/>- Configuración del sistema<br/>- Emergency functions<br/>- Fee management]
        MOD2[onlyMarketplace<br/>- Record purchases<br/>- Fee distribution<br/>- State updates]
        MOD3[onlyEscrow<br/>- Fund releases<br/>- Status updates<br/>- Refund processing]
    end

    subgraph "🛡️ Validaciones de Seguridad"
        VAL1[ReentrancyGuard<br/>🔒 Prevención de reentrancy]
        VAL2[Input Validation<br/>✅ Validación de parámetros]
        VAL3[State Checks<br/>📊 Verificación de estados]
        VAL4[Time Validations<br/>⏰ Validación de fechas]
    end

    subgraph "🚨 Funciones de Emergencia"
        EMERGENCY[Emergency Functions<br/>- pauseSystem()<br/>- emergencyWithdraw()<br/>- updateCriticalParams()]
    end

    OWNER --> MOD1
    MARKETPLACE --> MOD2
    ESCROW_ROLE --> MOD3

    MOD1 --> VAL1
    MOD2 --> VAL2
    MOD3 --> VAL3
    MOD1 --> VAL4

    MOD1 --> EMERGENCY

    %% Styling
    classDef roleClass fill:#ffecb3,stroke:#ff8f00,stroke-width:2px
    classDef controlClass fill:#e1f5fe,stroke:#0277bd,stroke-width:2px
    classDef validationClass fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef emergencyClass fill:#ffebee,stroke:#d32f2f,stroke-width:2px

    class OWNER,MARKETPLACE,ESCROW_ROLE roleClass
    class MOD1,MOD2,MOD3 controlClass
    class VAL1,VAL2,VAL3,VAL4 validationClass
    class EMERGENCY emergencyClass
```

---

## 📈 Métricas del Sistema

- **38 Tests** ejecutándose exitosamente ✅
- **12 Contratos** interconectados
- **5 Estados** de transacciones
- **Account Abstraction** completamente integrado
- **Sistema de Referidos** con códigos y expiraciones
- **Resolución de Disputas** con oráculos
- **Gestión de Comisiones** automatizada
- **Token Nativo** con staking integrado

El diagrama muestra la arquitectura completa del sistema Koneque Marketplace, destacando las interacciones entre contratos, flujos de datos, estados de transacciones y medidas de seguridad implementadas.
