#!/bin/bash

# SSL Certificate Renewal Script
# This script renews SSL certificates and restarts nginx

set -e

echo "🔄 SSL Certificate Renewal Started..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    print_error "docker-compose not found!"
    exit 1
fi

# Check if services are running
if ! docker-compose ps | grep -q "Up"; then
    print_error "Services are not running. Please start them first with: docker-compose up -d"
    exit 1
fi

print_status "Renewing SSL certificates..."

# Renew certificates
docker-compose run --rm certbot renew --quiet

if [ $? -eq 0 ]; then
    print_status "SSL certificates renewed successfully."
    
    # Restart nginx to reload certificates
    print_status "Restarting nginx..."
    docker-compose restart nginx
    
    if [ $? -eq 0 ]; then
        print_status "Nginx restarted successfully."
        echo -e "${GREEN}✅ SSL renewal completed successfully!${NC}"
    else
        print_error "Failed to restart nginx"
        exit 1
    fi
else
    print_warning "No certificates were renewed (they may not be due for renewal yet)"
fi

# Test HTTPS connectivity
print_status "Testing HTTPS connectivity..."
domains=("admin.azmarif.dev" "client.azmarif.dev" "server.azmarif.dev")

for domain in "${domains[@]}"; do
    if curl -s --max-time 10 -k "https://$domain/health" &>/dev/null; then
        print_status "✅ $domain is responding via HTTPS"
    else
        print_warning "⚠️ $domain not responding via HTTPS"
    fi
done

echo -e "${GREEN}🎉 SSL renewal process completed!${NC}"
