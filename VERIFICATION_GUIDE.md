# 🔑 Guía para Obtener API Key de BaseScan

## 📋 Pasos para Configurar Verificación de Contratos

### 1. Obtener API Key de BaseScan

1. **Visita BaseScan**: Ir a https://basescan.org/
2. **Crear cuenta**: Hacer clic en "Sign Up" y crear una cuenta
3. **Verificar email**: Confirmar tu email
4. **Acceder a API Keys**: 
   - Ir a tu perfil → "API Keys"
   - O visitar directamente: https://basescan.org/myapikey
5. **Crear nueva API Key**:
   - Hacer clic en "Add"
   - Nombre: "Koneque Contracts"
   - Confirmar creación
6. **Copiar API Key**: Guardar la key generada

### 2. Configurar Variables de Entorno

Agregar la API key a tu archivo `.env`:

```bash
# Existing variables
BASE_RPC_URL="https://mainnet.base.org"
BASE_SEPOLIA_RPC_URL="https://sepolia.base.org"
PRIVATE_KEY=0xf1f0b805524fea3b1f028732baa9c50380cff58a9ec048cb20f039888fd8626d

# Add this line with your actual API key
BASESCAN_API_KEY=YourActualApiKeyHere
```

### 3. Verificar Configuración

```bash
# Cargar variables
source .env

# Verificar que está configurado
echo $BASESCAN_API_KEY
```

## 🚀 Métodos de Verificación

### Método 1: Deploy con Verificación Automática

```bash
# Deploy y verificar en un solo comando
./interact.sh deploy
```

### Método 2: Verificación Manual Después del Deploy

```bash
# 1. Deployar contratos
source .env && forge script script/Deploy.s.sol:DeployScript --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast

# 2. Verificar contratos manualmente
./verify.sh
```

### Método 3: Verificación Individual

```bash
# Verificar un contrato específico
forge verify-contract <CONTRACT_ADDRESS> <CONTRACT_PATH> \
  --chain base-sepolia \
  --etherscan-api-key $BASESCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address)" <CONSTRUCTOR_ARG>)
```

## 📝 Ejemplos Específicos

### Verificar NativeToken (sin argumentos de constructor)
```bash
forge verify-contract 0x3422820Ef9FBC8e0206E4CBcB6369dBd14BE18c4 \
  src/token/NativeToken.sol:NativeToken \
  --chain base-sepolia \
  --etherscan-api-key $BASESCAN_API_KEY
```

### Verificar AccountFactory (con argumentos de constructor)
```bash
forge verify-contract 0x5f7272c1532b6B05558757AAC74e4D21E58DECAe \
  src/account/AccountFactory.sol:AccountFactory \
  --chain base-sepolia \
  --etherscan-api-key $BASESCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address)" 0x5B02258b1441F2850a45eb7949d83f6B103e731e)
```

## 🔍 Verificación de Estado

### Comprobar si un contrato está verificado:

```bash
# Método 1: Usando curl
curl "https://api-sepolia.basescan.org/api?module=contract&action=getabi&address=<CONTRACT_ADDRESS>&apikey=$BASESCAN_API_KEY"

# Método 2: Visitar en el navegador
# https://sepolia.basescan.org/address/<CONTRACT_ADDRESS>#code
```

### Verificar todos los contratos:

```bash
./interact.sh check
```

## ⚠️ Problemas Comunes

### 1. "Contract source code already verified"
- **Causa**: El contrato ya está verificado
- **Solución**: No es necesario hacer nada

### 2. "Unable to locate ContractName"
- **Causa**: Ruta incorrecta del contrato o nombre incorrecto
- **Solución**: Verificar que la ruta sea exacta: `src/folder/Contract.sol:ContractName`

### 3. "Invalid constructor arguments"
- **Causa**: Argumentos del constructor incorrectos
- **Solución**: Usar `cast abi-encode` para generar argumentos correctos

### 4. "Rate limit exceeded"
- **Causa**: Demasiadas requests a la API
- **Solución**: Esperar unos minutos antes de reintentar

## 📊 Beneficios de la Verificación

- ✅ **Transparencia**: Código fuente visible públicamente
- ✅ **Confianza**: Los usuarios pueden revisar el código
- ✅ **Interacción**: Facilita la interacción desde exploradores
- ✅ **Debugging**: Mejor experiencia de desarrollo
- ✅ **Auditorías**: Facilita auditorías de seguridad

## 🔗 Enlaces Útiles

- **BaseScan Mainnet**: https://basescan.org/
- **BaseScan Sepolia**: https://sepolia.basescan.org/
- **API Documentation**: https://docs.basescan.org/
- **Foundry Verification Docs**: https://book.getfoundry.sh/reference/forge/forge-verify-contract
