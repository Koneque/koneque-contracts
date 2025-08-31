#!/bin/bash

# Koneque Contracts Verification Script
# Base Sepolia - 2025-08-31

# Load environment variables
source .env

# Check if required environment variables are set
if [ -z "$BASESCAN_API_KEY" ]; then
    echo "❌ Error: BASESCAN_API_KEY not set in .env file"
    echo "Get your API key from: https://basescan.org/apis"
    exit 1
fi

if [ -z "$BASE_SEPOLIA_RPC_URL" ]; then
    echo "❌ Error: BASE_SEPOLIA_RPC_URL not set in .env file"
    exit 1
fi

# Contract addresses (replace with your actual deployed addresses)
NATIVE_TOKEN="0x3422820Ef9FBC8e0206E4CBcB6369dBd14BE18c4"
SMART_ACCOUNT="0x5B02258b1441F2850a45eb7949d83f6B103e731e"
ACCOUNT_FACTORY="0x5f7272c1532b6B05558757AAC74e4D21E58DECAe"
PAYMASTER="0x5FCA60cbb22e38F8172ae6BA41FFCfad007a41BD"
MARKETPLACE_CORE="0xbB4fE95d722457484Bc42453d5346a166C7bCAE9"
ESCROW="0xdE0E60DCaf3e8b36F3C92a9Ea6D97C0e9a3ca194"
FEE_MANAGER="0x4EF6c34dEEae92d4a6314Ba0C0C76fBe1E8360D0"
DISPUTE_RESOLUTION="0x4A1E9765473e4E29EB77250360622c6251D2D4e1"
ORACLE_REGISTRY="0xA6680F13c455655C458807C96AEf1947E87572B2"
REFERRAL_SYSTEM="0xB0EBE476289D5070E18Fb7e4C6F44Ce97Be30211"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to verify a contract
verify_contract() {
    local name=$1
    local address=$2
    local contract_path=$3
    local constructor_args=$4
    
    print_info "Verifying $name at $address..."
    
    local cmd="forge verify-contract $address $contract_path --chain base-sepolia --etherscan-api-key $BASESCAN_API_KEY"
    
    if [ ! -z "$constructor_args" ]; then
        cmd="$cmd --constructor-args $constructor_args"
    fi
    
    echo "Command: $cmd"
    
    if eval $cmd; then
        print_success "$name verified successfully!"
        echo "Explorer: https://sepolia.basescan.org/address/$address#code"
    else
        print_error "Failed to verify $name"
        return 1
    fi
    
    echo ""
}

# Function to encode constructor arguments
encode_constructor_args() {
    local signature=$1
    shift
    local args="$@"
    
    cast abi-encode "$signature" $args
}

print_info "🔍 Starting contract verification on Base Sepolia..."
echo ""

# Verify NativeToken (no constructor args)
verify_contract "NativeToken" $NATIVE_TOKEN "src/token/NativeToken.sol:NativeToken"

# Verify SmartAccount (no constructor args)
verify_contract "SmartAccount" $SMART_ACCOUNT "src/account/SmartAccount.sol:SmartAccount"

# Verify AccountFactory (constructor: address _implementation)
ACCOUNT_FACTORY_ARGS=$(encode_constructor_args "constructor(address)" $SMART_ACCOUNT)
verify_contract "AccountFactory" $ACCOUNT_FACTORY "src/account/AccountFactory.sol:AccountFactory" $ACCOUNT_FACTORY_ARGS

# Verify Paymaster (constructor: address _nativeToken)
PAYMASTER_ARGS=$(encode_constructor_args "constructor(address)" $NATIVE_TOKEN)
verify_contract "Paymaster" $PAYMASTER "src/account/Paymaster.sol:Paymaster" $PAYMASTER_ARGS

# Verify Escrow (constructor: address _nativeToken)
ESCROW_ARGS=$(encode_constructor_args "constructor(address)" $NATIVE_TOKEN)
verify_contract "Escrow" $ESCROW "src/marketplace/Escrow.sol:Escrow" $ESCROW_ARGS

# Verify FeeManager (constructor: address _nativeToken, address _platformWallet)
# Note: You need to replace PLATFORM_WALLET with the actual platform wallet address
PLATFORM_WALLET=$(cast wallet address --private-key $PRIVATE_KEY)
FEE_MANAGER_ARGS=$(encode_constructor_args "constructor(address,address)" $NATIVE_TOKEN $PLATFORM_WALLET)
verify_contract "FeeManager" $FEE_MANAGER "src/marketplace/FeeManager.sol:FeeManager" $FEE_MANAGER_ARGS

# Verify MarketplaceCore (constructor: address _nativeToken)
MARKETPLACE_ARGS=$(encode_constructor_args "constructor(address)" $NATIVE_TOKEN)
verify_contract "MarketplaceCore" $MARKETPLACE_CORE "src/marketplace/MarketplaceCore.sol:MarketplaceCore" $MARKETPLACE_ARGS

# Verify DisputeResolution (constructor: address _nativeToken)
DISPUTE_ARGS=$(encode_constructor_args "constructor(address)" $NATIVE_TOKEN)
verify_contract "DisputeResolution" $DISPUTE_RESOLUTION "src/dispute/DisputeResolution.sol:DisputeResolution" $DISPUTE_ARGS

# Verify OracleRegistry (constructor: address _nativeToken)
ORACLE_ARGS=$(encode_constructor_args "constructor(address)" $NATIVE_TOKEN)
verify_contract "OracleRegistry" $ORACLE_REGISTRY "src/dispute/OracleRegistry.sol:OracleRegistry" $ORACLE_ARGS

# Verify ReferralSystem (constructor: address _nativeToken)
REFERRAL_ARGS=$(encode_constructor_args "constructor(address)" $NATIVE_TOKEN)
verify_contract "ReferralSystem" $REFERRAL_SYSTEM "src/incentives/ReferralSystem.sol:ReferralSystem" $REFERRAL_ARGS

print_success "🎉 Verification process completed!"
print_info "Check all contracts at: https://sepolia.basescan.org/"
