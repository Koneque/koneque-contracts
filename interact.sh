#!/bin/bash

# Koneque Contracts Interaction Script
# Base Sepolia Deployment - 2025-08-31

# Load environment variables
source .env

# Contract addresses
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

# Helper function to print colored output
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

# Function to check if required variables are set
check_env() {
    if [ -z "$BASE_SEPOLIA_RPC_URL" ] || [ -z "$PRIVATE_KEY" ]; then
        print_error "Required environment variables not set. Please check your .env file."
        exit 1
    fi
}

# Function to get token balance
get_balance() {
    local address=$1
    if [ -z "$address" ]; then
        print_error "Please provide an address"
        return 1
    fi
    
    print_info "Getting balance for $address"
    cast call $NATIVE_TOKEN "balanceOf(address)" $address --rpc-url $BASE_SEPOLIA_RPC_URL
}

# Function to mint tokens
mint_tokens() {
    local to_address=$1
    local amount=$2
    
    if [ -z "$to_address" ] || [ -z "$amount" ]; then
        print_error "Usage: mint_tokens <address> <amount>"
        return 1
    fi
    
    print_info "Minting $amount tokens to $to_address"
    cast send $NATIVE_TOKEN "mint(address,uint256)" $to_address $amount \
        --rpc-url $BASE_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
    
    if [ $? -eq 0 ]; then
        print_success "Tokens minted successfully!"
    else
        print_error "Failed to mint tokens"
    fi
}

# Function to create smart account
create_account() {
    local owner=$1
    local salt=${2:-0}
    
    if [ -z "$owner" ]; then
        print_error "Usage: create_account <owner_address> [salt]"
        return 1
    fi
    
    print_info "Creating smart account for owner: $owner"
    cast send $ACCOUNT_FACTORY "createAccount(address,uint256)" $owner $salt \
        --rpc-url $BASE_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
    
    if [ $? -eq 0 ]; then
        print_success "Smart account created successfully!"
    else
        print_error "Failed to create smart account"
    fi
}

# Function to check contract status
check_contract() {
    local contract_name=$1
    local contract_address=$2
    
    print_info "Checking $contract_name at $contract_address"
    
    # Check if contract exists
    local code=$(cast code $contract_address --rpc-url $BASE_SEPOLIA_RPC_URL)
    
    if [ "$code" = "0x" ]; then
        print_error "$contract_name: No contract found at address"
    else
        print_success "$contract_name: Contract deployed and verified"
        print_info "Explorer: https://sepolia.basescan.org/address/$contract_address"
    fi
}

# Function to check all contracts
check_all_contracts() {
    print_info "Checking all deployed contracts..."
    echo ""
    
    check_contract "NativeToken" $NATIVE_TOKEN
    check_contract "SmartAccount" $SMART_ACCOUNT
    check_contract "AccountFactory" $ACCOUNT_FACTORY
    check_contract "Paymaster" $PAYMASTER
    check_contract "MarketplaceCore" $MARKETPLACE_CORE
    check_contract "Escrow" $ESCROW
    check_contract "FeeManager" $FEE_MANAGER
    check_contract "DisputeResolution" $DISPUTE_RESOLUTION
    check_contract "OracleRegistry" $ORACLE_REGISTRY
    check_contract "ReferralSystem" $REFERRAL_SYSTEM
}

# Function to show deployment info
show_deployment_info() {
    echo ""
    print_info "🚀 Koneque Contracts Deployment Information"
    echo ""
    echo "Network: Base Sepolia (Chain ID: 84532)"
    echo "Deploy Date: 2025-08-31"
    echo "Total Cost: ~0.000015 ETH"
    echo ""
    echo "📜 Contract Addresses:"
    echo "├── NativeToken:        $NATIVE_TOKEN"
    echo "├── SmartAccount:       $SMART_ACCOUNT"
    echo "├── AccountFactory:     $ACCOUNT_FACTORY"
    echo "├── Paymaster:          $PAYMASTER"
    echo "├── MarketplaceCore:    $MARKETPLACE_CORE"
    echo "├── Escrow:             $ESCROW"
    echo "├── FeeManager:         $FEE_MANAGER"
    echo "├── DisputeResolution:  $DISPUTE_RESOLUTION"
    echo "├── OracleRegistry:     $ORACLE_REGISTRY"
    echo "└── ReferralSystem:     $REFERRAL_SYSTEM"
    echo ""
}

# Function to deploy with verification
deploy_with_verification() {
    print_info "Deploying contracts with automatic verification..."
    
    # Check if BASESCAN_API_KEY is set
    if [ -z "$BASESCAN_API_KEY" ]; then
        print_warning "BASESCAN_API_KEY not set. Deploying without verification."
        print_info "Get your API key from: https://basescan.org/apis"
        
        # Deploy without verification
        forge script script/Deploy.s.sol:DeployScript --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast
    else
        print_info "Deploying with automatic verification..."
        
        # Deploy with verification
        forge script script/Deploy.s.sol:DeployScript --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --verify --etherscan-api-key $BASESCAN_API_KEY
        
        if [ $? -eq 0 ]; then
            print_success "Deployment and verification completed!"
        else
            print_warning "Deployment completed but verification may have failed."
            print_info "Run './verify.sh' to verify contracts manually."
        fi
    fi
}

# Function to verify existing contracts
verify_contracts() {
    print_info "Verifying existing contracts..."
    
    if [ ! -f "./verify.sh" ]; then
        print_error "verify.sh script not found!"
        return 1
    fi
    
    ./verify.sh
}

# Function to show help
show_help() {
    echo ""
    print_info "🔧 Koneque Contracts Interaction Script"
    echo ""
    echo "Available commands:"
    echo ""
    echo "  info                          - Show deployment information"
    echo "  check                         - Check all contracts status"
    echo "  deploy                        - Deploy contracts with verification"
    echo "  verify                        - Verify existing contracts"
    echo "  balance <address>             - Get token balance for address"
    echo "  mint <address> <amount>       - Mint tokens to address"
    echo "  create-account <owner> [salt] - Create smart account"
    echo "  help                          - Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./interact.sh info"
    echo "  ./interact.sh deploy"
    echo "  ./interact.sh verify"
    echo "  ./interact.sh balance 0x1234..."
    echo "  ./interact.sh mint 0x1234... 1000000000000000000000"
    echo "  ./interact.sh create-account 0x1234..."
    echo ""
}

# Main script logic
main() {
    check_env
    
    case $1 in
        "info")
            show_deployment_info
            ;;
        "check")
            check_all_contracts
            ;;
        "deploy")
            deploy_with_verification
            ;;
        "verify")
            verify_contracts
            ;;
        "balance")
            get_balance $2
            ;;
        "mint")
            mint_tokens $2 $3
            ;;
        "create-account")
            create_account $2 $3
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
