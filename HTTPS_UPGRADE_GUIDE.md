# HTTPS Upgrade Guide

This guide explains how to upgrade your PickOne deployment from HTTP to HTTPS when you're ready.

## Current Setup

Your deployment is configured for HTTP-only to ensure smooth initial setup:

-   🖥️ Admin Panel: http://admin.azmarif.dev
-   📱 Client App: http://client.azmarif.dev
-   🚀 API Server: http://server.azmarif.dev

## When to Upgrade to HTTPS

You can upgrade to HTTPS anytime after your HTTP deployment is working properly. HTTPS is recommended for:

-   Production environments
-   Handling sensitive data
-   SEO benefits
-   User trust

## Prerequisites

Before upgrading to HTTPS, ensure:

1. ✅ HTTP deployment is working: `curl http://admin.azmarif.dev/health`
2. ✅ DNS is properly configured: `dig admin.azmarif.dev`
3. ✅ Firewall allows ports 80 and 443: `ufw status`
4. ✅ Services are running: `docker-compose ps`

## Upgrade Process

### Step 1: Run the SSL Setup Script

```bash
./ssl-setup.sh
```

This script will:

-   ✅ Check all prerequisites
-   📋 Backup your current HTTP configuration
-   🔒 Obtain SSL certificates from Let's Encrypt
-   🔄 Update nginx configuration for HTTPS
-   🚀 Test HTTPS connectivity
-   🔄 Set up automatic HTTP→HTTPS redirects

### Step 2: Verify HTTPS is Working

After the script completes, test your sites:

```bash
curl https://admin.azmarif.dev/health
curl https://client.azmarif.dev/health
curl https://server.azmarif.dev/health
```

### Step 3: Set Up Automatic Renewal

SSL certificates expire every 90 days. Set up automatic renewal:

```bash
# Test renewal script
./ssl-renew.sh

# Add to crontab for automatic renewal (runs twice daily)
crontab -e
# Add this line:
0 12 * * * /path/to/pickone-deploy/ssl-renew.sh >> /path/to/pickone-deploy/ssl-renewal.log 2>&1
```

## After HTTPS Upgrade

Your sites will be available at:

-   🔒 Admin Panel: https://admin.azmarif.dev
-   🔒 Client App: https://client.azmarif.dev
-   🔒 API Server: https://server.azmarif.dev

HTTP URLs will automatically redirect to HTTPS.

## Rollback (if needed)

If you need to rollback to HTTP-only:

```bash
# Find your backup
ls nginx-backup-*/

# Restore HTTP configuration
cp nginx-backup-YYYYMMDD-HHMMSS/nginx.conf.http nginx.conf

# Restart nginx
docker-compose restart nginx
```

## Troubleshooting

### SSL Certificate Issues

```bash
# Check certificate status
docker-compose run --rm certbot certificates

# Manual renewal
docker-compose run --rm certbot renew --dry-run
```

### Nginx Issues

```bash
# Check nginx logs
docker-compose logs nginx

# Test nginx configuration
docker-compose exec nginx nginx -t
```

### DNS Issues

```bash
# Check DNS resolution
dig admin.azmarif.dev
nslookup admin.azmarif.dev
```

### Connectivity Issues

```bash
# Check if ports are open
nmap -p 80,443 admin.azmarif.dev

# Check firewall
ufw status
```

## Security Features (After HTTPS)

Your HTTPS setup includes:

-   🔒 TLS 1.2/1.3 encryption
-   🛡️ HSTS headers
-   🚫 Mixed content protection
-   🔄 Automatic HTTP→HTTPS redirects
-   ⚡ HTTP/2 support
-   🔐 Secure SSL ciphers
-   📊 Rate limiting
-   🛡️ Security headers

## Need Help?

If you encounter issues during the upgrade:

1. Check the prerequisites section
2. Review the troubleshooting section
3. Check nginx and certbot logs
4. Ensure DNS is properly propagated (can take up to 24 hours)

The HTTP deployment will continue working normally if HTTPS setup fails.
