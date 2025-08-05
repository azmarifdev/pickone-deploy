# PickOne Production Deployment Guide

This project is configured for production deployment on VPS with Docker and HTTPS SSL certificates.

## 🌐 Domains Configuration

The project uses 3 domains:

-   **Admin Panel**: https://admin.azmarif.dev
-   **Client App**: https://client.azmarif.dev
-   **API Server**: https://server.azmarif.dev

All domains should point to VPS IP: `103.213.38.213`

## � Quick Deployment

### 1. Pre-deployment Check

```bash
# Check system requirements and configuration
./pre-deploy-check.sh
```

### 2. Deploy Application

```bash
# Deploy with automatic SSL setup
./deploy.sh
```

### 3. Health Check

```bash
# Verify all services are running
./health-check.sh
```

### 4. SSL Management

```bash
# Renew SSL certificates (automated via cron)
./ssl-renew.sh
```

## �📋 Prerequisites

-   VPS with Ubuntu/Linux
-   Docker & Docker Compose installed
-   Domain DNS records configured
-   Ports 80, 443 open on firewall

## 🚀 Quick Deployment

### 1. Pre-deployment Check

```bash
./pre-deploy-check.sh
```

### 2. Deploy Everything

```bash
./deploy.sh
```

The deployment script will:

-   ✅ Install Docker (if not installed)
-   ✅ Create environment files from examples
-   ✅ Set up SSL certificates via Let's Encrypt
-   ✅ Start all services with Docker Compose
-   ✅ Seed database with admin user
-   ✅ Run health checks

## 📁 Project Structure

```
.
├── docker-compose.yaml     # Main orchestration file
├── nginx.conf             # Nginx reverse proxy config
├── deploy.sh              # Main deployment script
├── pre-deploy-check.sh    # Pre-deployment validation
├── setup-env.sh           # Environment setup helper
├── monitor.sh             # Service monitoring
├── backup.sh              # Database backup script
├── fix-ssl.sh             # SSL troubleshooting helper
├── server-tmp/            # File upload directory
├── pickone-admin/         # Admin panel (Next.js)
├── pickone-client/        # Client app (Next.js)
└── pickone-server/        # Backend API (Express.js)
```

## 🔧 Environment Variables

### Main .env

```env
# Database
MONGODB_URI=mongodb://admin:your_password@mongodb:27017/pickone?authSource=admin

# JWT
JWT_SECRET=your_super_secure_jwt_secret_here
JWT_EXPIRES_IN=7d

# Admin Credentials
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=securepassword123

# Production URLs
ADMIN_URL=https://admin.azmarif.dev
CLIENT_URL=https://client.azmarif.dev
SERVER_URL=https://server.azmarif.dev
```

### Service Environment Files

Each service (admin/client/server) has its own `.env` file with specific configurations.

## 🎯 Admin Access

After deployment, access admin panel:

-   **Login**: https://admin.azmarif.dev/auth/signin
-   **Dashboard**: https://admin.azmarif.dev/dashboard

Default admin credentials:

-   Email: `admin@example.com`
-   Password: `securepassword123`

## 🗂️ File Upload

Files are stored in `server-tmp/` directory and served via:
`https://server.azmarif.dev/server-tmp/filename.ext`

## 📊 Monitoring & Maintenance

### Check Service Status

```bash
./monitor.sh
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f pickone-admin
docker-compose logs -f pickone-client
docker-compose logs -f pickone-backend
docker-compose logs -f nginx
```

### Database Backup

```bash
./backup.sh
```

### SSL Certificate Renewal

SSL certificates auto-renew via cron job. Manual renewal:

```bash
./fix-ssl.sh
```

## 🔍 Troubleshooting

### Container Issues

```bash
# Restart all services
docker-compose restart

# Rebuild and restart
docker-compose down
docker-compose up --build -d
```

### SSL Issues

```bash
# Check SSL status
./fix-ssl.sh

# Check nginx config
docker-compose exec nginx nginx -t

# Reload nginx
docker-compose exec nginx nginx -s reload
```

### Database Issues

```bash
# Connect to MongoDB
docker-compose exec mongodb mongosh -u admin -p your_password

# View database
use pickone
show collections
```

## 🌟 Production Features

-   ✅ **HTTPS SSL** with auto-renewal
-   ✅ **Rate limiting** and security headers
-   ✅ **Health monitoring** endpoints
-   ✅ **Automated backups**
-   ✅ **File upload** system
-   ✅ **Database seeding** with admin user
-   ✅ **Container restart** policies
-   ✅ **Nginx reverse proxy** with caching

## 📞 Support

For issues or questions:

1. Check logs: `docker-compose logs`
2. Run health check: `./monitor.sh`
3. Validate setup: `./pre-deploy-check.sh`

---

**Happy Deploying! 🚀**
