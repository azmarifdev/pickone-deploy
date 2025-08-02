#!/bin/bash

# Environment Setup Script for PickOne Services
# This script sets up environment files for all services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🔧 Setting up environment files for PickOne services..."

# Check if main .env exists
if [ ! -f .env ]; then
    print_warning "Main .env file not found. Creating from template..."
    if [ -f .env.example ]; then
        cp .env.example .env
        print_success "Created main .env from template"
        print_warning "Please edit .env file to update JWT secrets and other production values!"
    else
        print_error ".env.example not found! Cannot create .env file."
        exit 1
    fi
else
    print_success "Main .env file found"
fi

# Function to setup service environment
setup_service_env() {
    local service_name=$1
    local service_dir=$2
    
    print_status "Setting up $service_name environment..."
    
    if [ -d "$service_dir" ]; then
        # Copy main .env to service directory
        cp .env "$service_dir/.env"
        
        # If service has its own .env.example, merge the values
        if [ -f "$service_dir/.env.example" ]; then
            # Append service-specific variables that aren't in main .env
            while IFS= read -r line; do
                # Skip comments and empty lines
                [[ $line =~ ^[[:space:]]*# ]] && continue
                [[ -z "$line" ]] && continue
                
                # Extract variable name
                var_name=$(echo "$line" | cut -d'=' -f1)
                
                # Check if variable exists in main .env
                if ! grep -q "^$var_name=" .env; then
                    echo "$line" >> "$service_dir/.env"
                fi
            done < "$service_dir/.env.example"
        fi
        
        print_success "$service_name environment configured"
    else
        print_warning "$service_dir directory not found, skipping $service_name"
    fi
}

# Setup environments for each service
setup_service_env "Server" "pickone-server"
setup_service_env "Admin" "pickone-admin"  
setup_service_env "Client" "pickone-client"

# Verify environment files
print_status "Verifying environment files..."

for service in pickone-server pickone-admin pickone-client; do
    if [ -f "$service/.env" ]; then
        print_success "✓ $service/.env exists"
    else
        print_error "✗ $service/.env missing"
    fi
done

echo ""
print_success "Environment setup completed!"
print_warning "Important: Please review and update the following in your .env files:"
echo "  • JWT_SECRET_TOKEN - Use a strong, unique secret"
echo "  • JWT_REFRESH_TOKEN - Use a strong, unique secret"
echo "  • Database credentials if needed"
echo "  • Facebook tokens if using Facebook integration"
echo ""
print_status "To edit main environment: nano .env"
print_status "To edit service environments: nano [service-name]/.env"
