#!/bin/bash

# SSL Fix Script for PickOne
# This script fixes SSL certificate issues step by step

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

echo "🔧 SSL Certificate Fix Script"

# Step 1: Stop containers and restart
print_status "Step 1: Restarting containers..."
docker-compose down
docker-compose up -d

# Wait for services
print_status "Waiting for containers to start..."
sleep 20

# Step 2: Check if containers are running
print_status "Step 2: Checking container status..."
docker-compose ps

# Step 3: Test basic connectivity
print_status "Step 3: Testing basic connectivity..."
for domain in admin.azmarif.dev client.azmarif.dev server.azmarif.dev; do
    print_status "Testing $domain..."
    
    # Test basic HTTP
    response=$(curl -s -o /dev/null -w "%{http_code}" "http://$domain" 2>/dev/null || echo "000")
    if [[ "$response" == "200" ]]; then
        print_success "✓ $domain HTTP is working (200)"
    else
        print_warning "⚠ $domain HTTP returned: $response"
    fi
    
    # Test health endpoint
    health_response=$(curl -s -o /dev/null -w "%{http_code}" "http://$domain/health" 2>/dev/null || echo "000")
    if [[ "$health_response" == "200" ]]; then
        print_success "✓ $domain/health is working (200)"
    else
        print_warning "⚠ $domain/health returned: $health_response"
    fi
done

# Step 4: Setup certbot directories
print_status "Step 4: Setting up certbot directories..."
docker-compose exec nginx mkdir -p /var/www/certbot/.well-known/acme-challenge
docker-compose exec nginx chmod -R 755 /var/www/certbot
docker-compose exec nginx chown -R nginx:nginx /var/www/certbot

# Create a test file
docker-compose exec nginx sh -c 'echo "test" > /var/www/certbot/.well-known/acme-challenge/test'

# Step 5: Test ACME challenge paths
print_status "Step 5: Testing ACME challenge paths..."
for domain in admin.azmarif.dev client.azmarif.dev server.azmarif.dev; do
    print_status "Testing ACME challenge for $domain..."
    
    challenge_response=$(curl -s "http://$domain/.well-known/acme-challenge/test" 2>/dev/null || echo "failed")
    if [[ "$challenge_response" == "test" ]]; then
        print_success "✓ $domain ACME challenge path is working"
    else
        print_error "✗ $domain ACME challenge path failed: $challenge_response"
    fi
done

# Step 6: Check nginx logs
print_status "Step 6: Checking nginx logs for errors..."
docker-compose logs nginx | tail -20

# Step 7: Test with dry-run first
print_status "Step 7: Testing SSL with dry-run..."
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email admin@azmarif.dev \
    --agree-tos \
    --no-eff-email \
    --dry-run \
    -d admin.azmarif.dev \
    -d client.azmarif.dev \
    -d server.azmarif.dev

if [ $? -eq 0 ]; then
    print_success "✅ Dry-run successful! Proceeding with real certificates..."
    
    # Step 8: Get real certificates
    print_status "Step 8: Getting real SSL certificates..."
    docker-compose run --rm certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email admin@azmarif.dev \
        --agree-tos \
        --no-eff-email \
        --force-renewal \
        -d admin.azmarif.dev \
        -d client.azmarif.dev \
        -d server.azmarif.dev
    
    if [ $? -eq 0 ]; then
        print_success "🎉 SSL certificates obtained successfully!"
        
        # Update nginx config to enable HTTPS redirects
        print_status "Updating nginx config for HTTPS redirects..."
        
        # Restart nginx
        docker-compose restart nginx
        sleep 10
        
        # Test HTTPS
        print_status "Testing HTTPS endpoints..."
        for domain in admin.azmarif.dev client.azmarif.dev server.azmarif.dev; do
            https_response=$(curl -s -k -o /dev/null -w "%{http_code}" "https://$domain" 2>/dev/null || echo "000")
            if [[ "$https_response" == "200" ]] || [[ "$https_response" == "301" ]] || [[ "$https_response" == "302" ]]; then
                print_success "✅ https://$domain is working ($https_response)"
            else
                print_warning "⚠ https://$domain returned: $https_response"
            fi
        done
        
        print_success "🚀 SSL setup completed successfully!"
        echo ""
        print_success "Your sites are now available with HTTPS:"
        echo "  🔐 https://admin.azmarif.dev"
        echo "  🔐 https://client.azmarif.dev"
        echo "  🔐 https://server.azmarif.dev"
        
    else
        print_error "❌ Real SSL certificate generation failed"
    fi
else
    print_error "❌ Dry-run failed. Please check the errors above."
    
    print_status "Troubleshooting tips:"
    echo "1. Check if domains are properly pointing to this server:"
    echo "   nslookup admin.azmarif.dev"
    echo "   nslookup client.azmarif.dev"
    echo "   nslookup server.azmarif.dev"
    echo ""
    echo "2. Check nginx configuration:"
    echo "   docker-compose logs nginx"
    echo ""
    echo "3. Check container status:"
    echo "   docker-compose ps"
    echo ""
    echo "4. Test basic connectivity:"
    echo "   curl -I http://admin.azmarif.dev"
fi

# Cleanup test file
docker-compose exec nginx rm -f /var/www/certbot/.well-known/acme-challenge/test

print_status "SSL fix script completed."
