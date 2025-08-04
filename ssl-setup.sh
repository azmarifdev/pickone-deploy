#!/bin/bash

# SSL Setup Script - Step by step approach
# This handles SSL certificate generation safely

set -e

echo "🔐 Starting SSL Certificate Setup..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Start with HTTP-only nginx
print_status "Step 1: Setting up HTTP-only nginx for SSL challenge..."

# Backup current nginx.conf
cp nginx.conf nginx.conf.backup

# Create temporary HTTP-only nginx config
cat > nginx-temp.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # HTTP server for SSL challenge
    server {
        listen 80;
        server_name admin.azmarif.dev client.azmarif.dev server.azmarif.dev;
        
        # Let's Encrypt ACME challenge
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
            try_files $uri $uri/ =404;
        }
        
        # Health check
        location /health {
            return 200 "OK";
            add_header Content-Type text/plain;
        }
        
        # Temporary response for SSL setup
        location / {
            return 200 "Setting up SSL certificates...";
            add_header Content-Type text/plain;
        }
    }
}
EOF

# Replace nginx config temporarily
cp nginx-temp.conf nginx.conf

print_status "Starting containers with HTTP-only config..."
docker-compose up -d nginx certbot

# Wait for nginx to start
sleep 5

# Step 2: Generate SSL certificates
print_status "Step 2: Generating SSL certificates..."

domains=("admin.azmarif.dev" "client.azmarif.dev" "server.azmarif.dev")

for domain in "${domains[@]}"; do
    print_status "Generating certificate for $domain..."
    
    docker-compose exec certbot certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email azmarifdev@gmail.com \
        --agree-tos \
        --no-eff-email \
        --staging \
        -d $domain
    
    if [ $? -eq 0 ]; then
        print_status "✅ Certificate generated for $domain"
    else
        print_error "❌ Failed to generate certificate for $domain"
        # Restore original config
        cp nginx.conf.backup nginx.conf
        exit 1
    fi
done

# Step 3: Generate production certificates
print_status "Step 3: Generating production certificates..."

for domain in "${domains[@]}"; do
    print_status "Generating production certificate for $domain..."
    
    docker-compose exec certbot certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email azmarifdev@gmail.com \
        --agree-tos \
        --no-eff-email \
        --force-renewal \
        -d $domain
    
    if [ $? -eq 0 ]; then
        print_status "✅ Production certificate generated for $domain"
    else
        print_error "❌ Failed to generate production certificate for $domain"
        # Restore original config
        cp nginx.conf.backup nginx.conf
        exit 1
    fi
done

# Step 4: Restore full nginx config and restart
print_status "Step 4: Restoring full nginx configuration..."
cp nginx.conf.backup nginx.conf

print_status "Restarting nginx with SSL configuration..."
docker-compose restart nginx

# Clean up
rm nginx-temp.conf nginx.conf.backup

print_status "🎉 SSL setup completed successfully!"
print_status "Your domains are now available with HTTPS:"
for domain in "${domains[@]}"; do
    echo "  ✅ https://$domain"
done
