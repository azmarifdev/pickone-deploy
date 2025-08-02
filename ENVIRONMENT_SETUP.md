# 🔧 Environment Configuration Guide

এই guide আপনাকে সব service এর environment variables properly configure করতে সাহায্য করবে।

## 📁 Environment Files Structure

```
pickone-deploy/
├── .env                    # Main environment file
├── .env.example           # Main template
├── pickone-server/
│   ├── .env              # Server environment
│   └── .env.example      # Server template
├── pickone-admin/
│   ├── .env              # Admin environment
│   └── .env.example      # Admin template
└── pickone-client/
    ├── .env              # Client environment
    └── .env.example      # Client template
```

## 🚀 Quick Setup

### Automatic Setup:

```bash
# Run environment setup script
./setup-env.sh
```

### Manual Setup:

```bash
# 1. Create main environment file
cp .env.example .env

# 2. Create individual service environment files
cp .env pickone-server/.env
cp .env pickone-admin/.env
cp .env pickone-client/.env
```

## 🔑 Critical Environment Variables

### Main .env File:

```bash
# Production Environment
NODE_ENV=production

# Database Configuration
DB_USERNAME=pickone-db
DB_PASSWORD=OQAEKyl6PEhxFF59
DB_NAME=pickone-db
DATABASE_URL=mongodb://pickone-db:OQAEKyl6PEhxFF59@mongodb:27017/pickone-db?authSource=admin

# Production URLs
NEXT_PUBLIC_API_URL=https://server.azmarif.dev
NEXT_PUBLIC_CLIENT_URL=https://client.azmarif.dev
NEXT_PUBLIC_ADMIN_URL=https://admin.azmarif.dev
NEXT_PUBLIC_BASE_URL=https://server.azmarif.dev
LOCAL_FILE_URL=https://server.azmarif.dev/server-tmp/

# JWT Secrets (MUST CHANGE!)
JWT_SECRET_TOKEN=your_super_secure_jwt_secret_change_this
JWT_REFRESH_TOKEN=your_super_secure_refresh_secret_change_this
JWT_EXPIRE_IN=24h
JWT_REFRESH_EXPIRE_IN=7d

# File Upload
FILE_UPLOAD_PATH=/app/server-tmp
MAX_FILE_SIZE=104857600

# Security
BCRYPT_SALT_ROUNDS=12
CORS_ORIGIN=https://client.azmarif.dev,https://admin.azmarif.dev
```

## 🌐 Service-Specific Configurations

### 1. Server (.env in pickone-server/):

-   MongoDB connection
-   JWT secrets
-   File upload settings
-   Facebook API tokens
-   CORS configuration

### 2. Admin (.env in pickone-admin/):

-   API URLs for admin panel
-   Production environment settings

### 3. Client (.env in pickone-client/):

-   API URLs for client app
-   Google Analytics/GTM IDs
-   Meta Pixel IDs
-   Production environment settings

## ⚠️ Security Checklist

### Before Production Deployment:

-   [ ] **Change JWT Secrets**: Update `JWT_SECRET_TOKEN` and `JWT_REFRESH_TOKEN`
-   [ ] **Review Database Credentials**: Ensure secure passwords
-   [ ] **Verify API URLs**: All URLs should use HTTPS domains
-   [ ] **Check Facebook Tokens**: Ensure tokens are valid and secure
-   [ ] **Validate CORS Origins**: Only allow trusted domains

### JWT Secret Generation:

```bash
# Generate secure JWT secrets
openssl rand -base64 64  # For JWT_SECRET_TOKEN
openssl rand -base64 64  # For JWT_REFRESH_TOKEN
```

## 🔍 Environment Validation

### Check Environment Files:

```bash
# Verify all .env files exist
ls -la */**.env

# Check specific configurations
grep "NODE_ENV" */.env
grep "NEXT_PUBLIC_API_URL" */.env
```

### Test Configuration:

```bash
# Run environment setup validation
./setup-env.sh

# Check Docker environment loading
docker-compose config
```

## 🚨 Common Issues & Solutions

### 1. **Environment Variables Not Loading**

```bash
# Ensure .env files are in correct locations
ls -la pickone-*/.env

# Recreate environment files
./setup-env.sh
```

### 2. **JWT Secret Errors**

```bash
# Generate new secrets
echo "JWT_SECRET_TOKEN=$(openssl rand -base64 64)" >> .env
echo "JWT_REFRESH_TOKEN=$(openssl rand -base64 64)" >> .env
```

### 3. **API Connection Errors**

```bash
# Verify API URLs in all services
grep -r "NEXT_PUBLIC_API_URL" pickone-*/

# Ensure consistent URLs across services
```

### 4. **Database Connection Issues**

```bash
# Check DATABASE_URL format
grep "DATABASE_URL" .env

# Test MongoDB connection
docker-compose exec pickone-backend node -e "console.log(process.env.DATABASE_URL)"
```

## 📝 Environment Templates

### Development vs Production:

#### Development:

```bash
NODE_ENV=development
NEXT_PUBLIC_BASE_URL=http://localhost:5000
DATABASE_URL=mongodb://localhost:27017/pickone-dev
```

#### Production:

```bash
NODE_ENV=production
NEXT_PUBLIC_BASE_URL=https://server.azmarif.dev
DATABASE_URL=mongodb://pickone-db:OQAEKyl6PEhxFF59@mongodb:27017/pickone-db?authSource=admin
```

## 🔄 Update Environment Files

### After Changes:

```bash
# Update all service environments
cp .env pickone-server/.env
cp .env pickone-admin/.env
cp .env pickone-client/.env

# Restart services to load new environment
docker-compose restart
```

### Backup Current Environment:

```bash
# Create backup
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)

# Backup all service environments
mkdir -p env-backup
cp pickone-*/.env env-backup/
```

## ✅ Verification Checklist

After environment setup:

-   [ ] All `.env` files exist in service directories
-   [ ] JWT secrets are unique and secure
-   [ ] API URLs use HTTPS domains
-   [ ] Database credentials are correct
-   [ ] Facebook tokens are valid (if used)
-   [ ] File upload paths are configured
-   [ ] CORS origins are restricted to your domains
-   [ ] Environment files are not committed to git

## 🛠️ Quick Commands

```bash
# Setup all environments
./setup-env.sh

# Check environment loading
docker-compose config

# Restart with new environment
docker-compose down && docker-compose up -d

# View environment variables in container
docker-compose exec pickone-backend env | grep -E "(NODE_ENV|API_URL|JWT_)"
```

---

**⚠️ Important**: Never commit `.env` files to version control. Only commit `.env.example` files as templates.
