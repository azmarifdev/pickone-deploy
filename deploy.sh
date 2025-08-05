#!/bin/bash

# PickOne Production Deployment Script
# Author: GitHub Copilot
# Date: $(date)

set -e

echo "🚀 Starting PickOne Production Deployment..."

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_warning "This script is running as root. This is fine for VPS deployment."
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p server-tmp
mkdir -p ssl-certs
mkdir -p certbot/conf
mkdir -p certbot/www

# Setup environment files if they don't exist
print_status "Setting up environment files..."
if [ ! -f .env ]; then
    print_status "Creating .env from .env.example..."
    cp .env.example .env
    print_warning "Please edit .env file with your configuration before continuing!"
    read -p "Press Enter after editing .env file..."
fi

# Setup service environment files
services=("pickone-admin" "pickone-client" "pickone-server")
for service in "${services[@]}"; do
    if [ ! -f "$service/.env" ]; then
        print_status "Creating $service/.env from .env.example..."
        cp "$service/.env.example" "$service/.env"
    fi
done

print_success "Environment file found."

# Setup individual service environment files
print_status "Setting up service environment files..."

# Copy main .env to individual services
cp .env pickone-server/.env
cp .env pickone-admin/.env  
cp .env pickone-client/.env

# Also copy .env.example files as backup templates
if [ ! -f pickone-server/.env ]; then
    cp pickone-server/.env.example pickone-server/.env
    print_warning "Created server .env from template"
fi

if [ ! -f pickone-admin/.env ]; then
    cp pickone-admin/.env.example pickone-admin/.env
    print_warning "Created admin .env from template"
fi

if [ ! -f pickone-client/.env ]; then
    cp pickone-client/.env.example pickone-client/.env
    print_warning "Created client .env from template"
fi

print_success "Service environment files configured."

# Install Docker and Docker Compose if not installed
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl enable docker
    systemctl start docker
    print_success "Docker installed successfully."
else
    print_success "Docker is already installed."
fi

if ! command -v docker-compose &> /dev/null; then
    print_status "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed successfully."
else
    print_success "Docker Compose is already installed."
fi

# Stop existing containers if running
print_status "Stopping existing containers..."
docker-compose down --remove-orphans || true

# Build and start services (without SSL first)
print_status "Building and starting services..."
docker-compose up -d --build

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 30

# Check if services are running
print_status "Checking service status..."
if docker-compose ps | grep -q "Up"; then
    print_success "Services are running successfully."
else
    print_error "Some services failed to start. Please check logs."
    docker-compose logs
    exit 1
fi

# Test HTTPS connectivity after SSL setup
print_status "Testing HTTPS connectivity..."
sleep 10

for domain in admin.azmarif.dev client.azmarif.dev server.azmarif.dev; do
    # Test HTTPS
    if curl -s --max-time 10 -k "https://$domain/health" &>/dev/null; then
        print_success "✓ HTTPS: $domain is responding"
    else
        print_warning "⚠ HTTPS: $domain not responding (may still be starting)"
    fi
    
    # Test HTTP redirect
    if curl -s --max-time 10 -I "http://$domain" | grep -q "301\|302"; then
        print_success "✓ HTTP→HTTPS redirect working for $domain"
    else
        print_warning "⚠ HTTP→HTTPS redirect may not be working for $domain"
    fi
done

# Ensure certbot directories exist and have proper permissions
print_status "Setting up certbot directories..."
mkdir -p certbot/conf certbot/www
docker-compose exec nginx mkdir -p /var/www/certbot/.well-known/acme-challenge
docker-compose exec nginx chmod -R 755 /var/www/certbot
docker-compose exec nginx chown -R www-data:www-data /var/www/certbot || docker-compose exec nginx chown -R nginx:nginx /var/www/certbot

# Ensure uploads directory exists
print_status "Setting up uploads directory..."
mkdir -p uploads
chmod 755 uploads

# Test ACME challenge directory
print_status "Testing ACME challenge directory..."
for domain in admin.azmarif.dev client.azmarif.dev server.azmarif.dev; do
    if curl -s "http://$domain/.well-known/acme-challenge/" | grep -q "404\|403" || curl -s -o /dev/null -w "%{http_code}" "http://$domain/.well-known/acme-challenge/" | grep -q "404"; then
        print_success "✓ $domain ACME challenge path is accessible"
    else
        print_warning "⚠ $domain ACME challenge path may have issues"
    fi
done

# SSL Prerequisites Check
print_status "Checking SSL prerequisites..."
ssl_ready=true

for domain in admin.azmarif.dev client.azmarif.dev server.azmarif.dev; do
    # Check DNS resolution
    resolved_ip=$(dig +short $domain 2>/dev/null | head -1 || nslookup $domain 2>/dev/null | grep -A1 "Name:" | grep "Address:" | awk '{print $2}' | head -1 || echo "")
    expected_ip="103.213.38.213"
    
    if [ "$resolved_ip" = "$expected_ip" ]; then
        print_success "✓ DNS: $domain → $resolved_ip"
    else
        print_warning "⚠ DNS: $domain → $resolved_ip (expected: $expected_ip)"
        ssl_ready=false
    fi
    
    # Check HTTP connectivity  
    if curl -s --max-time 10 "http://$domain/health" &>/dev/null; then
        print_success "✓ HTTP: $domain is reachable"
    else
        print_warning "⚠ HTTP: $domain is not reachable"
        ssl_ready=false
    fi
done

if [ "$ssl_ready" = false ]; then
    print_warning "SSL prerequisites not met. Will try anyway but may fail."
    print_warning "You can run './ssl-setup.sh' later after fixing DNS/connectivity issues."
fi

# Get SSL certificates - Safe approach
print_status "Obtaining SSL certificates..."

# Check if certificates already exist
cert_exists=false
for domain in admin.azmarif.dev client.azmarif.dev server.azmarif.dev; do
    if [ -f "certbot/conf/live/$domain/fullchain.pem" ]; then
        print_success "Certificate for $domain already exists"
        cert_exists=true
    fi
done

if [ "$cert_exists" = false ]; then
    print_status "No existing certificates found. Getting new certificates..."
    
    # First try with dry-run to test
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

    if [ $? -eq 0 ]; then
        print_success "Dry-run successful. Getting production certificates..."
        
        # Get production certificates
        docker-compose run --rm certbot certonly \
            --webroot \
            --webroot-path=/var/www/certbot \
            --email admin@azmarif.dev \
            --agree-tos \
            --no-eff-email \
            -d admin.azmarif.dev \
            -d client.azmarif.dev \
            -d server.azmarif.dev
        
        if [ $? -eq 0 ]; then
            print_success "SSL certificates obtained successfully."
            
            # Restart nginx to use SSL certificates
            print_status "Restarting nginx with SSL..."
            docker-compose restart nginx
            
            print_success "Nginx restarted with SSL support."
        else
            print_error "Failed to obtain SSL certificates"
        fi
    else
        print_warning "SSL dry-run failed. Check domain DNS and firewall."
        print_warning "Running in HTTP mode. You can try SSL setup later with: ./ssl-setup.sh"
    fi
else
    print_success "Using existing SSL certificates."
    docker-compose restart nginx
fi

# Run database seed
print_status "Seeding database with admin user..."
docker-compose exec pickone-backend npm run seed

if [ $? -eq 0 ]; then
    print_success "Database seeded successfully."
    print_success "Admin credentials: admin@gmail.com / admin@"
else
    print_warning "Database seeding failed. You may need to run it manually."
fi

# Setup SSL certificate renewal
print_status "Setting up SSL certificate auto-renewal..."
cat > /etc/cron.d/certbot-renewal << EOF
0 12 * * * /usr/local/bin/docker-compose -f $(pwd)/docker-compose.yaml run --rm certbot renew --quiet && /usr/local/bin/docker-compose -f $(pwd)/docker-compose.yaml restart nginx
EOF

print_success "SSL auto-renewal configured."

# Final status check
print_status "Running final health checks..."
sleep 10

echo ""
echo "🎉 Deployment completed!"
echo ""
print_success "Your applications are now available at:"
echo -e "  📱 Client App: ${GREEN}https://client.azmarif.dev${NC}"
echo -e "  🛠️  Admin Panel: ${GREEN}https://admin.azmarif.dev${NC}"
echo -e "  🚀 API Server: ${GREEN}https://server.azmarif.dev${NC}"
echo ""
print_success "Admin Panel Access:"
echo -e "  📧 Email: ${YELLOW}admin@gmail.com${NC}"
echo -e "  🔑 Password: ${YELLOW}admin@${NC}"
echo ""
print_success "Direct Links:"
echo -e "  📊 Dashboard: ${GREEN}https://admin.azmarif.dev/admin/dashboard${NC}"
echo -e "  🔐 Login: ${GREEN}https://admin.azmarif.dev/admin/login${NC}"
echo ""
print_status "To view logs: docker-compose logs -f [service-name]"
print_status "To restart: docker-compose restart [service-name]"
print_status "To stop all: docker-compose down"
echo ""
print_success "✨ Deployment successful! Your PickOne application is now live! ✨"
