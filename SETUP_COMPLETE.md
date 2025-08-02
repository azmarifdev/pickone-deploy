# 🎉 PickOne Production Setup Complete!

আপনার জন্য সম্পূর্ণ production-ready setup তৈরি করা হয়েছে। এখানে সব details দেওয়া হলো:

## 🌐 Your Live Applications

| Service            | URL                        | Purpose         |
| ------------------ | -------------------------- | --------------- |
| **Admin Panel**    | https://admin.azmarif.dev  | Admin dashboard |
| **Client Website** | https://client.azmarif.dev | Customer site   |
| **API Server**     | https://server.azmarif.dev | Backend API     |

## 🔐 Admin Login Credentials

```
Email: admin@gmail.com
Password: admin@
Login URL: https://admin.azmarif.dev/admin/login
Dashboard: https://admin.azmarif.dev/admin/dashboard
```

## 🚀 Deployment Steps

### 1. VPS এ Connect করুন:

```bash
ssh root@103.213.38.213
# Password: j6VMSPpvuq4!
```

### 2. Repository Clone করুন:

```bash
cd /root
git clone https://github.com/azmarifdev/pickone-deploy.git
cd pickone-deploy
```

### 3. Environment Configure করুন:

```bash
cp .env.example .env
nano .env
```

### 4. Deploy করুন:

```bash
chmod +x deploy.sh
./deploy.sh
```

## 📁 Key Features Configured

✅ **HTTPS SSL Certificates** - Let's Encrypt auto-renewal  
✅ **Domain Routing** - তিনটি subdomain properly configured  
✅ **File Storage** - `server-tmp` folder for uploads  
✅ **Database Seeding** - Admin user automatically created  
✅ **Production Security** - Security headers, rate limiting  
✅ **Auto Restart** - Containers restart automatically  
✅ **Monitoring** - Health check scripts included  
✅ **Backup System** - Database and files backup script

## 🛠️ Management Commands

### Basic Operations:

```bash
# Check status
docker-compose ps

# View logs
docker-compose logs -f [service-name]

# Restart service
docker-compose restart [service-name]

# Stop all
docker-compose down

# Start all
docker-compose up -d
```

### Monitoring:

```bash
# Full health check
./monitor.sh

# Watch mode (continuous monitoring)
./monitor.sh watch

# Quick check
./monitor.sh quick
```

### Backup:

```bash
# Create backup
./backup.sh

# Backups stored in: /root/pickone-backups/
```

### SSL Management:

```bash
# Manual SSL setup (if needed)
./setup-ssl.sh

# Check SSL status
./monitor.sh
```

## 📂 File Structure

```
pickone-deploy/
├── docker-compose.yaml     # Main deployment config
├── nginx.conf             # Nginx configuration
├── .env                   # Environment variables
├── deploy.sh              # Auto deployment script
├── setup-ssl.sh           # SSL certificate setup
├── monitor.sh             # Health monitoring
├── backup.sh              # Backup script
├── server-tmp/            # File upload directory
├── pickone-admin/         # Admin panel code
├── pickone-client/        # Client app code
└── pickone-server/        # Backend API code
```

## 🔄 Admin Panel Routes

| Route         | URL                                       | Purpose                     |
| ------------- | ----------------------------------------- | --------------------------- |
| Login         | https://admin.azmarif.dev/admin/login     | Admin login                 |
| Dashboard     | https://admin.azmarif.dev/admin/dashboard | Main dashboard              |
| Root Redirect | https://admin.azmarif.dev/                | Auto redirects to dashboard |

## 📊 File Upload System

-   **Upload Location**: `/app/server-tmp/` (inside container)
-   **Host Location**: `./server-tmp/` (on VPS)
-   **Web Access**: `https://server.azmarif.dev/server-tmp/[filename]`
-   **Max Size**: 100MB per file

## 🔒 Security Features

-   **SSL/TLS** encryption for all domains
-   **HTTP to HTTPS** redirect
-   **Security headers** (HSTS, CSP, etc.)
-   **Rate limiting** on API endpoints
-   **CORS** properly configured
-   **File upload** validation

## 🚨 Troubleshooting

### Common Issues:

1. **Services not starting:**

    ```bash
    docker-compose logs
    docker-compose restart [service-name]
    ```

2. **SSL certificate issues:**

    ```bash
    ./setup-ssl.sh
    ```

3. **Database connection:**

    ```bash
    docker-compose exec pickone-backend npm run seed
    ```

4. **Admin can't login:**
    - Check credentials: admin@gmail.com / admin@
    - Re-run seed: `docker-compose exec pickone-backend npm run seed`

## 📱 Testing Your Setup

1. **Admin Panel**: https://admin.azmarif.dev/admin/login
2. **Client Site**: https://client.azmarif.dev
3. **API Health**: https://server.azmarif.dev/health

## 🔄 Future Updates

```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose up -d --build

# Check status
./monitor.sh
```

## 📞 Support Commands

```bash
# View all containers
docker-compose ps

# Check resource usage
docker stats

# View system resources
df -h && free -h

# Test all endpoints
curl -I https://admin.azmarif.dev
curl -I https://client.azmarif.dev
curl -I https://server.azmarif.dev
```

---

## ✨ আপনার setup সম্পূর্ণ!

🎊 **Congratulations!** আপনার PickOne application এখন fully production-ready এবং live!

**Key URLs to remember:**

-   🏠 **Client**: https://client.azmarif.dev
-   🛠️ **Admin**: https://admin.azmarif.dev
-   🚀 **API**: https://server.azmarif.dev

**Admin Access:**

-   📧 Email: admin@gmail.com
-   🔑 Password: admin@

আপনার application এখন HTTPS সহ fully secure এবং production-ready! 🚀
