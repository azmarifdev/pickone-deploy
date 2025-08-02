# 🚀 PickOne Production Deployment Guide

Complete guide for deploying PickOne application on VPS with Docker, HTTPS, and custom domains.

## 📋 Prerequisites

-   ✅ VPS with Ubuntu/Debian (IP: 103.213.38.213)
-   ✅ Domain DNS A records configured:
    -   `admin.azmarif.dev` → 103.213.38.213
    -   `client.azmarif.dev` → 103.213.38.213
    -   `server.azmarif.dev` → 103.213.38.213
-   ✅ SSH access to VPS
-   ✅ Ports 80, 443, 22 open on firewall

## 🔧 VPS Server Information

```
IP: 103.213.38.213
User: root
Password: j6VMSPpvuq4!
```

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         NGINX (SSL Termination)            │
│                    admin.azmarif.dev                        │
│                    client.azmarif.dev                       │
│                    server.azmarif.dev                       │
└─────────────────────┬───────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┬─────────────────────────┐
        │             │             │                         │
┌───────▼──────┐ ┌────▼────┐ ┌──────▼──────┐ ┌──────────────┐
│ PickOne     │ │ PickOne │ │ PickOne     │ │   MongoDB    │
│ Admin       │ │ Client  │ │ Server      │ │   Database   │
│ (Port 3000) │ │(Port 4000)│ │ (Port 5000) │ │ (Port 27017) │
└─────────────┘ └─────────┘ └─────────────┘ └──────────────┘
```

## 🚀 Quick Deployment (Automatic)

### Step 1: Connect to VPS

```bash
ssh root@103.213.38.213
# Password: j6VMSPpvuq4!
```

### Step 2: Clone Repository

```bash
cd /root
git clone https://github.com/azmarifdev/pickone-deploy.git
cd pickone-deploy
```

### Step 3: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit environment variables (IMPORTANT!)
nano .env
```

**Required Environment Variables:**

```bash
# Database (Keep existing or change)
DB_USERNAME=pickone-db
DB_PASSWORD=OQAEKyl6PEhxFF59
DB_NAME=pickone-db

# JWT Secrets (MUST CHANGE!)
JWT_SECRET=your_super_secure_jwt_secret_here_change_this
JWT_REFRESH_SECRET=your_super_secure_refresh_secret_here_change_this

# Production URLs (Already configured)
NEXT_PUBLIC_API_URL=https://server.azmarif.dev
NEXT_PUBLIC_CLIENT_URL=https://client.azmarif.dev
NEXT_PUBLIC_ADMIN_URL=https://admin.azmarif.dev
```

### Step 4: Run Deployment Script

```bash
# Make script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

The script will:

-   ✅ Install Docker & Docker Compose
-   ✅ Build all containers
-   ✅ Obtain SSL certificates
-   ✅ Configure NGINX with HTTPS
-   ✅ Seed admin user
-   ✅ Setup SSL auto-renewal

## 🔐 Admin Access Credentials

After deployment, access the admin panel with:

```
📧 Email: admin@gmail.com
🔑 Password: admin@
🌐 URL: https://admin.azmarif.dev/admin/login
📊 Dashboard: https://admin.azmarif.dev/admin/dashboard
```

## 🌍 Application URLs

| Service         | URL                        | Purpose                        |
| --------------- | -------------------------- | ------------------------------ |
| **Admin Panel** | https://admin.azmarif.dev  | Admin dashboard and management |
| **Client App**  | https://client.azmarif.dev | Customer-facing application    |
| **API Server**  | https://server.azmarif.dev | Backend API and file serving   |

## 📁 File Storage

Files are stored in the `server-tmp` directory:

-   **Local Path**: `/root/pickone-deploy/server-tmp/`
-   **Container Path**: `/app/server-tmp/`
-   **Web URL**: `https://server.azmarif.dev/server-tmp/`

## 🔧 Manual Setup (If Automatic Fails)

### 1. Install Docker Manually

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl enable docker
systemctl start docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

### 2. Start Services

```bash
# Create directories
mkdir -p server-tmp ssl-certs certbot/conf certbot/www

# Start services
docker-compose up -d --build
```

### 3. Setup SSL Manually

```bash
# Make SSL script executable
chmod +x setup-ssl.sh

# Run SSL setup
./setup-ssl.sh
```

### 4. Seed Admin User

```bash
# Run database seed
docker-compose exec pickone-backend npm run seed
```

## 🔍 Troubleshooting

### Check Service Status

```bash
# View all containers
docker-compose ps

# View logs
docker-compose logs -f [service-name]

# Examples:
docker-compose logs -f pickone-backend
docker-compose logs -f pickone-admin
docker-compose logs -f nginx
```

### Common Issues

#### 1. SSL Certificate Failed

```bash
# Check domain DNS
nslookup admin.azmarif.dev
nslookup client.azmarif.dev
nslookup server.azmarif.dev

# Manually run SSL setup
./setup-ssl.sh
```

#### 2. Services Not Starting

```bash
# Check logs
docker-compose logs

# Restart specific service
docker-compose restart [service-name]

# Rebuild and restart
docker-compose up -d --build [service-name]
```

#### 3. Database Connection Issues

```bash
# Check MongoDB
docker-compose logs mongodb

# Check if MongoDB is accessible
docker-compose exec pickone-backend ping mongodb
```

#### 4. Admin User Not Created

```bash
# Manually run seed
docker-compose exec pickone-backend npm run seed

# Check if database is accessible
docker-compose exec mongodb mongo --eval "db.runCommand('ismaster')"
```

## 🔄 Management Commands

### Start/Stop Services

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart specific service
docker-compose restart [service-name]

# View real-time logs
docker-compose logs -f
```

### Update Application

```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose up -d --build
```

### Database Operations

```bash
# Access MongoDB shell
docker-compose exec mongodb mongo

# Backup database
docker-compose exec mongodb mongodump --out /data/backup

# Restore database
docker-compose exec mongodb mongorestore /data/backup
```

### SSL Certificate Renewal

SSL certificates auto-renew via cron job. Manual renewal:

```bash
# Manual renewal
docker-compose run --rm certbot renew

# Restart nginx after renewal
docker-compose restart nginx
```

## 🔒 Security Considerations

1. **Change Default Passwords**: Update all default passwords in `.env`
2. **JWT Secrets**: Use strong, unique JWT secrets
3. **Firewall**: Ensure only ports 80, 443, 22 are open
4. **Regular Updates**: Keep Docker images updated
5. **Backup**: Regular database backups
6. **Monitoring**: Monitor logs for suspicious activity

## 📊 Monitoring

### View System Resources

```bash
# Docker resource usage
docker stats

# Disk usage
df -h

# View running processes
docker-compose top
```

### Health Checks

```bash
# Test all endpoints
curl -I https://admin.azmarif.dev
curl -I https://client.azmarif.dev
curl -I https://server.azmarif.dev/health
```

## 🆘 Support

If you encounter issues:

1. Check logs: `docker-compose logs -f`
2. Verify DNS settings
3. Ensure ports 80/443 are accessible
4. Check `.env` configuration
5. Try manual SSL setup with `./setup-ssl.sh`

## ✅ Post-Deployment Checklist

-   [ ] All containers running (`docker-compose ps`)
-   [ ] HTTPS working for all domains
-   [ ] Admin login successful
-   [ ] Database seeded with admin user
-   [ ] File uploads working
-   [ ] SSL auto-renewal configured
-   [ ] Backup strategy in place

---

🎉 **Your PickOne application is now live in production!**

**Access URLs:**

-   🏠 Client: https://client.azmarif.dev
-   🛠️ Admin: https://admin.azmarif.dev
-   🚀 API: https://server.azmarif.dev
