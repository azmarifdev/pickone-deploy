#!/bin/bash

echo "🔍 Pre-deployment validation started..."

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check required files
echo "📁 Checking required files..."
files=(
    "docker-compose.yaml"
    "nginx.conf"
    ".env.example"
    "pickone-admin/.env.example"
    "pickone-admin/Dockerfile"
    "pickone-client/.env.example"
    "pickone-client/Dockerfile"
    "pickone-server/.env.example"
    "pickone-server/Dockerfile"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        print_status 0 "$file exists"
    else
        print_status 1 "$file missing"
    fi
done

# Check Docker
echo -e "\n🐳 Checking Docker..."
if command -v docker &> /dev/null; then
    print_status 0 "Docker is installed"
    if docker info &> /dev/null; then
        print_status 0 "Docker daemon is running"
    else
        print_status 1 "Docker daemon is not running"
    fi
else
    print_status 1 "Docker is not installed"
fi

# Check Docker Compose
if command -v docker-compose &> /dev/null; then
    print_status 0 "Docker Compose is installed"
else
    print_status 1 "Docker Compose is not installed"
fi

# Check if containers are running
echo -e "\n📦 Checking existing containers..."
if command -v docker &> /dev/null && docker info &> /dev/null; then
    running_containers=$(docker ps --format "{{.Names}}" 2>/dev/null | grep -v '^$' || true)
    if [ -n "$running_containers" ]; then
        print_warning "Some containers are already running:"
        echo "$running_containers" | while read container; do
            echo "  - $container"
        done
    else
        print_status 0 "No containers running (clean state)"
    fi
else
    print_warning "Cannot check container status"
fi

# Check required directories
echo -e "\n📂 Checking required directories..."
required_dirs=("uploads" "certbot/conf" "certbot/www")
for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        print_status 0 "Directory $dir exists"
    else
        print_warning "Directory $dir will be created during deployment"
    fi
done

# Check nginx configuration
echo -e "\n� Checking nginx configuration..."
if [ -f "nginx.conf" ]; then
    # Test nginx config syntax (if nginx is available)
    if command -v nginx &> /dev/null; then
        if nginx -t -c $(pwd)/nginx.conf &> /dev/null; then
            print_status 0 "nginx.conf syntax is valid"
        else
            print_status 1 "nginx.conf has syntax errors"
        fi
    else
        print_warning "nginx not installed locally - will test in container"
    fi
    
    # Check if all required server blocks exist
    required_servers=("admin.azmarif.dev" "client.azmarif.dev" "server.azmarif.dev")
    for server in "${required_servers[@]}"; do
        if grep -q "server_name $server" nginx.conf; then
            print_status 0 "nginx config includes $server"
        else
            print_status 1 "nginx config missing server block for $server"
        fi
    done
else
    print_status 1 "nginx.conf not found"
fi
ports=(80 443 3000 4000 5000 27017)
for port in "${ports[@]}"; do
    if lsof -i :$port &> /dev/null; then
        print_warning "Port $port is in use"
    else
        print_status 0 "Port $port is available"
    fi
done

# Check DNS resolution
echo -e "\n🌐 Checking DNS resolution..."
domains=("admin.azmarif.dev" "client.azmarif.dev" "server.azmarif.dev")
expected_ip="103.213.38.213"

for domain in "${domains[@]}"; do
    # Try multiple DNS tools
    resolved_ip=""
    
    # Try nslookup first
    if command -v nslookup &> /dev/null; then
        resolved_ip=$(nslookup $domain 2>/dev/null | grep -A1 "Name:" | grep "Address:" | awk '{print $2}' | head -1)
    fi
    
    # Try dig if nslookup failed
    if [ -z "$resolved_ip" ] && command -v dig &> /dev/null; then
        resolved_ip=$(dig +short $domain 2>/dev/null | head -1)
    fi
    
    # Try host if both failed
    if [ -z "$resolved_ip" ] && command -v host &> /dev/null; then
        resolved_ip=$(host $domain 2>/dev/null | grep "has address" | awk '{print $4}' | head -1)
    fi
    
    # Try getent if all DNS tools failed
    if [ -z "$resolved_ip" ] && command -v getent &> /dev/null; then
        resolved_ip=$(getent hosts $domain 2>/dev/null | awk '{print $1}' | head -1)
    fi
    
    if [ -n "$resolved_ip" ]; then
        if [ "$resolved_ip" = "$expected_ip" ]; then
            print_status 0 "$domain resolves to correct IP ($resolved_ip)"
        else
            print_warning "$domain resolves to $resolved_ip (expected: $expected_ip)"
        fi
    else
        print_status 1 "$domain DNS resolution failed (try: ping $domain)"
    fi
done

# Check if environment files exist
echo -e "\n🔧 Checking environment files..."
env_files=(
    ".env"
    "pickone-admin/.env"
    "pickone-client/.env"
    "pickone-server/.env"
)

for env_file in "${env_files[@]}"; do
    if [ -f "$env_file" ]; then
        print_status 0 "$env_file exists"
    else
        print_warning "$env_file not found (will be created from .env.example)"
    fi
done

# Check disk space
echo -e "\n💾 Checking disk space..."
available_space=$(df -h . | awk 'NR==2 {print $4}')
print_status 0 "Available disk space: $available_space"

echo -e "\n🏁 Pre-deployment check completed!"
echo -e "\n${GREEN}✨ Ready to deploy? Run: ./deploy.sh${NC}"
