#!/bin/bash

# SSL Certificate Setup Script for PickOne
# This script helps to manually obtain SSL certificates if the automatic process fails

set -e

echo "🔒 SSL Certificate Setup for PickOne"

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

# Create necessary directories
print_status "Creating SSL directories..."
mkdir -p certbot/conf
mkdir -p certbot/www
mkdir -p ssl-certs

# Check if containers are running
if ! docker-compose ps | grep -q "Up"; then
    print_error "Docker containers are not running. Please run 'docker-compose up -d' first."
    exit 1
fi

print_status "Containers are running. Proceeding with SSL setup..."

# Step 1: Create temporary nginx config for HTTP challenge
print_status "Creating temporary nginx config for ACME challenge..."

cat > nginx-temp.conf << 'EOF'
server {
    listen 80;
    server_name admin.azmarif.dev client.azmarif.dev server.azmarif.dev;
    
    # Let's Encrypt ACME challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # Temporary routes for testing
    location / {
        return 200 "Server is ready for SSL setup";
        add_header Content-Type text/plain;
    }
}
EOF

# Copy temp config and restart nginx
print_status "Applying temporary nginx configuration..."
docker cp nginx-temp.conf pickone-nginx:/etc/nginx/conf.d/default.conf
docker-compose restart nginx

print_status "Waiting for nginx to start..."
sleep 10

# Step 2: Test domains are accessible
print_status "Testing domain accessibility..."
for domain in admin.azmarif.dev client.azmarif.dev server.azmarif.dev; do
    if curl -s -o /dev/null -w "%{http_code}" http://$domain | grep -q "200"; then
        print_success "✓ $domain is accessible"
    else
        print_warning "⚠ $domain may not be accessible. Check DNS settings."
    fi
done

# Step 3: Obtain SSL certificates
print_status "Obtaining SSL certificates..."

# Try to get certificates for all domains at once
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email admin@azmarif.dev \
    --agree-tos \
    --no-eff-email \
    --expand \
    -d admin.azmarif.dev \
    -d client.azmarif.dev \
    -d server.azmarif.dev

if [ $? -eq 0 ]; then
    print_success "SSL certificates obtained successfully!"
    
    # Step 4: Apply production nginx config
    print_status "Applying production nginx configuration..."
    docker cp nginx.conf pickone-nginx:/etc/nginx/conf.d/default.conf
    docker-compose restart nginx
    
    print_success "Production nginx configuration applied!"
    
    # Step 5: Test HTTPS
    print_status "Testing HTTPS connections..."
    sleep 15
    
    for domain in admin.azmarif.dev client.azmarif.dev server.azmarif.dev; do
        if curl -s -k -o /dev/null -w "%{http_code}" https://$domain | grep -q "200\|301\|302"; then
            print_success "✓ https://$domain is working"
        else
            print_warning "⚠ https://$domain may have issues"
        fi
    done
    
    print_success "✨ SSL setup completed successfully!"
    echo ""
    print_success "Your sites are now available with HTTPS:"
    echo -e "  🔐 https://admin.azmarif.dev"
    echo -e "  🔐 https://client.azmarif.dev" 
    echo -e "  🔐 https://server.azmarif.dev"
    
else
    print_error "SSL certificate generation failed!"
    print_status "Possible solutions:"
    echo "  1. Check if domains are properly pointing to this server (103.213.38.213)"
    echo "  2. Make sure ports 80 and 443 are open"
    echo "  3. Wait a few minutes for DNS propagation"
    echo "  4. Try running this script again"
    
    # Restore original nginx config
    print_status "Restoring original nginx configuration..."
    docker cp nginx.conf pickone-nginx:/etc/nginx/conf.d/default.conf
    docker-compose restart nginx
fi

# Cleanup
rm -f nginx-temp.conf

print_status "SSL setup script completed."
