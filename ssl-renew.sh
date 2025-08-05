#!/bin/bash

# SSL Certificate Renewal Script
# This script renews SSL certificates and restarts nginx
# Works with both manual renewal and automated cron jobs

set -e

echo "🔄 SSL Certificate Renewal Started..."

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

# Check if HTTPS is enabled by looking for SSL certificates
domains=("admin.azmarif.dev" "client.azmarif.dev" "server.azmarif.dev")
ssl_enabled=false

for domain in "${domains[@]}"; do
    if [ -f "certbot/conf/live/$domain/fullchain.pem" ]; then
        ssl_enabled=true
        break
    fi
done

if [ "$ssl_enabled" = false ]; then
    print_error "No SSL certificates found. This appears to be an HTTP-only deployment."
    print_status "To enable HTTPS, run: ./ssl-setup.sh"
    exit 1
fi

print_status "SSL certificates found. Proceeding with renewal..."

# Check certificate expiry before renewal
print_status "Checking certificate expiry dates..."
for domain in "${domains[@]}"; do
    if [ -f "certbot/conf/live/$domain/fullchain.pem" ]; then
        expiry_date=$(openssl x509 -enddate -noout -in "certbot/conf/live/$domain/fullchain.pem" | cut -d= -f2)
        days_until_expiry=$(( ($(date -d "$expiry_date" +%s) - $(date +%s)) / 86400 ))
        
        if [ $days_until_expiry -le 30 ]; then
            print_warning "⚠️ $domain certificate expires in $days_until_expiry days"
        else
            print_success "✅ $domain certificate valid for $days_until_expiry days"
        fi
    fi
done

print_status "Renewing SSL certificates..."

# Try to renew certificates (dry-run first if manual execution)
if [ -t 1 ]; then
    # Interactive mode - do dry run first
    print_status "Running dry-run to test renewal..."
    docker-compose run --rm certbot renew --dry-run --quiet
    
    if [ $? -eq 0 ]; then
        print_success "Dry-run successful. Proceeding with actual renewal..."
    else
        print_error "Dry-run failed. Check certbot configuration."
        exit 1
    fi
fi

# Actual renewal
renewal_output=$(docker-compose run --rm certbot renew --quiet 2>&1)
renewal_status=$?

if [ $renewal_status -eq 0 ]; then
    if echo "$renewal_output" | grep -q "No renewals were attempted"; then
        print_status "No certificates were renewed (they are not due for renewal yet)"
        renewed=false
    else
        print_success "SSL certificates renewed successfully!"
        renewed=true
    fi
    
    # Always restart nginx if this is a manual run, or if certificates were actually renewed
    if [ -t 1 ] || [ "$renewed" = true ]; then
        print_status "Restarting nginx to reload certificates..."
        docker-compose restart nginx
        
        if [ $? -eq 0 ]; then
            print_success "Nginx restarted successfully"
        else
            print_error "Failed to restart nginx"
            exit 1
        fi
    fi
    
else
    print_error "Certificate renewal failed"
    print_error "$renewal_output"
    exit 1
fi

# Test HTTPS connectivity after renewal
print_status "Testing HTTPS connectivity..."
sleep 5

all_working=true
for domain in "${domains[@]}"; do
    https_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://$domain/health" || echo "000")
    if [ "$https_code" = "200" ]; then
        print_success "✅ $domain is responding via HTTPS (code: $https_code)"
    else
        print_error "❌ $domain not responding via HTTPS (code: $https_code)"
        all_working=false
    fi
    
    # Check certificate validity
    cert_info=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "")
    if [ -n "$cert_info" ]; then
        print_success "✅ $domain certificate is valid"
    else
        print_warning "⚠️ $domain certificate validation failed"
    fi
done

echo ""
if [ "$all_working" = true ]; then
    print_success "🎉 SSL renewal process completed successfully!"
    echo ""
    print_status "Your HTTPS sites are working properly:"
    echo -e "  🖥️  Admin Panel: ${GREEN}https://admin.azmarif.dev${NC}"
    echo -e "  📱 Client App:  ${GREEN}https://client.azmarif.dev${NC}"
    echo -e "  🚀 API Server:  ${GREEN}https://server.azmarif.dev${NC}"
else
    print_warning "SSL renewal completed but some services may have issues"
    print_status "Check nginx logs: docker-compose logs nginx"
fi

# Log completion for cron jobs
echo "$(date): SSL renewal completed" >> ssl-renewal.log
