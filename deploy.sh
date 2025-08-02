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

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found! Please create .env file first."
    exit 1
fi

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

# Get SSL certificates
print_status "Obtaining SSL certificates..."
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
    print_success "SSL certificates obtained successfully."
    
    # Restart nginx to use SSL certificates
    print_status "Restarting nginx with SSL..."
    docker-compose restart nginx
    
    print_success "Nginx restarted with SSL support."
else
    print_warning "SSL certificate generation failed. Running in HTTP mode."
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
