#!/bin/bash

# PickOne Production Monitoring Script
# This script helps monitor the health of your PickOne deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

check_service_health() {
    local service_name=$1
    local url=$2
    local expected_code=${3:-200}
    
    echo -e "\n${CYAN}Checking $service_name...${NC}"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")
    
    if [[ "$response" == "$expected_code" ]] || [[ "$response" == "301" ]] || [[ "$response" == "302" ]]; then
        print_success "$service_name is responding (HTTP $response)"
    else
        print_error "$service_name is not responding properly (HTTP $response)"
    fi
}

check_container_health() {
    local container_name=$1
    
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container_name.*Up"; then
        status=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$container_name" | awk '{print $2, $3, $4}')
        print_success "$container_name: $status"
    else
        print_error "$container_name: Not running or unhealthy"
    fi
}

# Main monitoring function
main() {
    clear
    print_header "🚀 PickOne Production Health Monitor"
    echo -e "${CYAN}Monitoring started at: $(date)${NC}\n"
    
    # Check Docker service
    print_header "🐳 Docker Service Status"
    if systemctl is-active --quiet docker; then
        print_success "Docker service is running"
    else
        print_error "Docker service is not running"
        echo "Try: sudo systemctl start docker"
    fi
    
    # Check container health
    print_header "📦 Container Health Status"
    check_container_health "pickone-nginx"
    check_container_health "pickone-admin"
    check_container_health "pickone-client"
    check_container_health "pickone-backend"
    check_container_health "pickone-mongodb"
    
    # Check service endpoints
    print_header "🌐 Service Endpoint Health"
    check_service_health "Admin Panel" "https://admin.azmarif.dev"
    check_service_health "Client App" "https://client.azmarif.dev"
    check_service_health "API Server Health" "https://server.azmarif.dev/health"
    check_service_health "API Server Root" "https://server.azmarif.dev"
    
    # Check SSL certificates
    print_header "🔒 SSL Certificate Status"
    for domain in admin.azmarif.dev client.azmarif.dev server.azmarif.dev; do
        echo -e "\n${CYAN}Checking SSL for $domain...${NC}"
        expiry=$(echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -noout -dates 2>/dev/null | grep notAfter | cut -d= -f2)
        if [ -n "$expiry" ]; then
            expiry_date=$(date -d "$expiry" +%s)
            current_date=$(date +%s)
            days_until_expiry=$(( (expiry_date - current_date) / 86400 ))
            
            if [ $days_until_expiry -gt 30 ]; then
                print_success "$domain SSL expires in $days_until_expiry days"
            elif [ $days_until_expiry -gt 7 ]; then
                print_warning "$domain SSL expires in $days_until_expiry days (renew soon)"
            else
                print_error "$domain SSL expires in $days_until_expiry days (urgent renewal needed)"
            fi
        else
            print_error "$domain SSL certificate check failed"
        fi
    done
    
    # Check system resources
    print_header "💻 System Resources"
    
    # Disk usage
    echo -e "\n${CYAN}Disk Usage:${NC}"
    df -h | grep -E "(Filesystem|/dev/)" | grep -v tmpfs
    
    # Memory usage
    echo -e "\n${CYAN}Memory Usage:${NC}"
    free -h
    
    # Docker resource usage
    echo -e "\n${CYAN}Docker Container Resources:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    
    # Check database connectivity
    print_header "🗄️ Database Connectivity"
    if docker-compose exec -T pickone-backend node -e "
    const mongoose = require('mongoose');
    mongoose.connect(process.env.DATABASE_URL || 'mongodb://pickone-db:OQAEKyl6PEhxFF59@mongodb:27017/pickone-db?authSource=admin', {
        useNewUrlParser: true,
        useUnifiedTopology: true,
        serverSelectionTimeoutMS: 5000
    })
    .then(() => {
        console.log('Database connection successful');
        process.exit(0);
    })
    .catch(err => {
        console.error('Database connection failed:', err.message);
        process.exit(1);
    });
    " 2>/dev/null; then
        print_success "Database connection is healthy"
    else
        print_error "Database connection failed"
    fi
    
    # Check log errors
    print_header "📋 Recent Error Logs (Last 50 lines)"
    echo -e "\n${CYAN}Backend Errors:${NC}"
    docker-compose logs --tail=50 pickone-backend 2>/dev/null | grep -i error | tail -5 || echo "No recent errors found"
    
    echo -e "\n${CYAN}Nginx Errors:${NC}"
    docker-compose logs --tail=50 nginx 2>/dev/null | grep -i error | tail -5 || echo "No recent errors found"
    
    # Quick admin test
    print_header "🛠️ Admin Panel Quick Test"
    admin_response=$(curl -s -o /dev/null -w "%{http_code}" "https://admin.azmarif.dev/admin/login" 2>/dev/null || echo "000")
    if [[ "$admin_response" == "200" ]]; then
        print_success "Admin login page is accessible"
    else
        print_error "Admin login page is not accessible (HTTP $admin_response)"
    fi
    
    # File upload directory check
    print_header "📁 File Upload Directory"
    if [ -d "server-tmp" ]; then
        file_count=$(find server-tmp -type f | wc -l)
        dir_size=$(du -sh server-tmp 2>/dev/null | cut -f1)
        print_success "Upload directory exists: $file_count files, $dir_size total"
    else
        print_warning "Upload directory 'server-tmp' not found"
    fi
    
    # Summary
    print_header "📊 Health Summary"
    echo -e "${CYAN}Deployment Status:${NC}"
    echo "• Admin Panel: https://admin.azmarif.dev"
    echo "• Client App: https://client.azmarif.dev"
    echo "• API Server: https://server.azmarif.dev"
    echo ""
    echo -e "${CYAN}Management Commands:${NC}"
    echo "• View logs: docker-compose logs -f [service]"
    echo "• Restart service: docker-compose restart [service]"
    echo "• Stop all: docker-compose down"
    echo "• Start all: docker-compose up -d"
    echo ""
    echo -e "${GREEN}✅ Health check completed at $(date)${NC}"
}

# Handle script arguments
case "${1:-}" in
    "watch")
        while true; do
            main
            echo -e "\n${YELLOW}Refreshing in 30 seconds... (Press Ctrl+C to stop)${NC}"
            sleep 30
        done
        ;;
    "quick")
        # Quick check - just service endpoints
        print_header "🚀 Quick Health Check"
        check_service_health "Admin Panel" "https://admin.azmarif.dev"
        check_service_health "Client App" "https://client.azmarif.dev"
        check_service_health "API Server" "https://server.azmarif.dev/health"
        ;;
    *)
        main
        ;;
esac
