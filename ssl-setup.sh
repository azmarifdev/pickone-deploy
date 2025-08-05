#!/bin/bash

# Manual SSL Certificate Setup Script
# Use this if SSL failed during initial deployment

set -e

echo "🔒 Manual SSL Certificate Setup Started..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

print_status "Checking SSL prerequisites..."

# Check DNS and HTTP connectivity
ssl_ready=true
domains=("admin.azmarif.dev" "client.azmarif.dev" "server.azmarif.dev")
expected_ip="103.213.38.213"

for domain in "${domains[@]}"; do
    # Check DNS
    resolved_ip=$(dig +short $domain 2>/dev/null | head -1 || nslookup $domain 2>/dev/null | grep -A1 "Name:" | grep "Address:" | awk '{print $2}' | head -1 || echo "")
    
    if [ "$resolved_ip" = "$expected_ip" ]; then
        print_success "✓ DNS: $domain → $resolved_ip"
    else
        print_error "❌ DNS: $domain → $resolved_ip (expected: $expected_ip)"
        ssl_ready=false
    fi
    
    # Check HTTP connectivity
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://$domain/health" || echo "000")
    if [ "$http_code" = "200" ]; then
        print_success "✓ HTTP: $domain is reachable (code: $http_code)"
    else
        print_error "❌ HTTP: $domain not reachable (code: $http_code)"
        ssl_ready=false
    fi
    
    # Check ACME challenge path
    acme_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://$domain/.well-known/acme-challenge/" || echo "000")
    if [ "$acme_code" = "404" ] || [ "$acme_code" = "403" ]; then
        print_success "✓ ACME: $domain challenge path accessible"
    else
        print_warning "⚠ ACME: $domain challenge path (code: $acme_code)"
    fi
done

if [ "$ssl_ready" = false ]; then
    print_error "SSL prerequisites not met. Please fix the above issues first."
    echo ""
    print_status "Common fixes:"
    echo "  1. Check DNS: dig admin.azmarif.dev"
    echo "  2. Check firewall: ufw status"
    echo "  3. Wait for DNS propagation (up to 24 hours)"
    echo "  4. Verify services: docker-compose ps"
    exit 1
fi

print_success "All prerequisites met. Proceeding with SSL setup..."

# Check existing certificates
print_status "Checking for existing certificates..."
existing_certs=false

for domain in "${domains[@]}"; do
    if [ -f "certbot/conf/live/$domain/fullchain.pem" ]; then
        print_warning "Certificate for $domain already exists"
        existing_certs=true
    fi
done

if [ "$existing_certs" = true ]; then
    echo ""
    read -p "Existing certificates found. Do you want to renew them? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Exiting without changes."
        exit 0
    fi
fi

# Test with dry-run first
print_status "Testing SSL setup with dry-run..."
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

if [ $? -ne 0 ]; then
    print_error "SSL dry-run failed! Check the errors above."
    exit 1
fi

print_success "Dry-run successful! Getting production certificates..."

# Get production certificates
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email admin@azmarif.dev \
    --agree-tos \
    --no-eff-email \
    $([ "$existing_certs" = true ] && echo "--force-renewal" || echo "") \
    -d admin.azmarif.dev \
    -d client.azmarif.dev \
    -d server.azmarif.dev

if [ $? -eq 0 ]; then
    print_success "SSL certificates obtained successfully!"
    
    # Restart nginx to use new certificates
    print_status "Restarting nginx with SSL..."
    docker-compose restart nginx
    
    if [ $? -eq 0 ]; then
        print_success "Nginx restarted successfully!"
        
        # Test HTTPS connectivity
        print_status "Testing HTTPS connectivity..."
        sleep 10
        
        for domain in "${domains[@]}"; do
            https_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 -k "https://$domain/health" || echo "000")
            if [ "$https_code" = "200" ]; then
                print_success "✅ HTTPS working: $domain"
            else
                print_error "❌ HTTPS failed: $domain (code: $https_code)"
            fi
            
            # Test HTTP redirect
            redirect_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 -I "http://$domain" || echo "000")
            if [ "$redirect_code" = "301" ] || [ "$redirect_code" = "302" ]; then
                print_success "✅ HTTP→HTTPS redirect: $domain"
            else
                print_warning "⚠ HTTP→HTTPS redirect may not be working: $domain"
            fi
        done
        
        echo ""
        print_success "🎉 SSL setup completed successfully!"
        echo ""
        print_success "Your sites are now available via HTTPS:"
        echo -e "  🖥️  Admin Panel: ${GREEN}https://admin.azmarif.dev${NC}"
        echo -e "  📱 Client App:  ${GREEN}https://client.azmarif.dev${NC}"
        echo -e "  🚀 API Server:  ${GREEN}https://server.azmarif.dev${NC}"
        
    else
        print_error "Failed to restart nginx"
        exit 1
    fi
else
    print_error "Failed to obtain SSL certificates"
    exit 1
fi
