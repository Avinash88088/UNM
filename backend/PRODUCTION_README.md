# 🚀 AI Document Master - Production Deployment Guide

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Environment Setup](#environment-setup)
4. [Database Setup](#database-setup)
5. [Deployment Options](#deployment-options)
6. [Security Configuration](#security-configuration)
7. [Monitoring & Logging](#monitoring--logging)
8. [Backup & Recovery](#backup--recovery)
9. [Troubleshooting](#troubleshooting)

## ✅ Prerequisites

- **Node.js**: 18.x or higher
- **PostgreSQL**: 14.x or higher
- **Redis**: 6.x or higher
- **Docker**: 20.x or higher (optional)
- **Nginx**: 1.18+ (for reverse proxy)
- **SSL Certificate**: For HTTPS

## 🚀 Quick Start

### Option 1: Docker Compose (Recommended)

```bash
# Clone repository
git clone https://github.com/Avinash88088/UNM.git
cd UNM/backend

# Copy environment file
cp env.production.example .env

# Edit environment variables
nano .env

# Start services
docker-compose -f docker-compose.prod.yml up -d

# Check status
docker-compose -f docker-compose.prod.yml ps
```

### Option 2: Manual Deployment

```bash
# Install dependencies
npm install --production

# Setup environment
cp env.production.example .env
nano .env

# Start server
npm start
```

## 🔧 Environment Setup

### Required Environment Variables

```bash
# Server Configuration
NODE_ENV=production
PORT=3000
FRONTEND_URL=https://your-domain.com

# Database
DB_HOST=your-postgres-host
DB_PORT=5432
DB_NAME=ai_document_master_prod
DB_USER=your_db_user
DB_PASSWORD=your_secure_password

# Redis
REDIS_HOST=your-redis-host
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password

# JWT Secrets (Generate strong keys!)
JWT_SECRET=your-super-secure-jwt-secret
JWT_REFRESH_SECRET=your-super-secure-refresh-secret

# File Upload
UPLOAD_PATH=/var/uploads
MAX_FILE_SIZE=52428800
```

### Generate Secure JWT Secrets

```bash
# Generate JWT secrets
openssl rand -hex 64
openssl rand -hex 64

# Or use Node.js
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

## 🗄️ Database Setup

### PostgreSQL Setup

```sql
-- Create database
CREATE DATABASE ai_document_master_prod;

-- Create user
CREATE USER ai_doc_user WITH PASSWORD 'secure_password_123';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE ai_document_master_prod TO ai_doc_user;

-- Run migrations
\c ai_document_master_prod
\i database/schema.sql
```

### Redis Setup

```bash
# Install Redis
sudo apt update
sudo apt install redis-server

# Configure Redis
sudo nano /etc/redis/redis.conf

# Set password
requirepass your_redis_password

# Restart Redis
sudo systemctl restart redis
```

## 🚀 Deployment Options

### 1. Docker Deployment (Recommended)

```bash
# Build and run
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f api

# Scale API service
docker-compose -f docker-compose.prod.yml up -d --scale api=3
```

### 2. PM2 Deployment

```bash
# Install PM2
npm install -g pm2

# Start application
pm2 start src/server.js --name "ai-document-master"

# Save PM2 configuration
pm2 save

# Setup PM2 startup script
pm2 startup
```

### 3. Systemd Service

```bash
# Create service file
sudo nano /etc/systemd/system/ai-document-master.service

[Unit]
Description=AI Document Master API
After=network.target

[Service]
Type=simple
User=ai_doc_user
WorkingDirectory=/var/www/ai-document-master
ExecStart=/usr/bin/node src/server.js
Restart=always
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target

# Enable and start service
sudo systemctl enable ai-document-master
sudo systemctl start ai-document-master
```

## 🔒 Security Configuration

### 1. Firewall Setup

```bash
# UFW Firewall
sudo ufw enable
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 3000/tcp  # API (if exposed directly)
```

### 2. Nginx Reverse Proxy

```nginx
# /etc/nginx/sites-available/ai-document-master
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # API Proxy
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # File uploads
    location /uploads/ {
        alias /var/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Health check
    location /health {
        proxy_pass http://localhost:3000;
    }
}
```

### 3. SSL with Let's Encrypt

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 📊 Monitoring & Logging

### 1. Application Logs

```bash
# View logs
tail -f logs/app.log

# Log rotation
sudo nano /etc/logrotate.d/ai-document-master

/var/www/ai-document-master/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 ai_doc_user ai_doc_user
}
```

### 2. System Monitoring

```bash
# Install monitoring tools
sudo apt install htop iotop nethogs

# Monitor system resources
htop
iotop
nethogs
```

### 3. Database Monitoring

```bash
# PostgreSQL monitoring
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"
sudo -u postgres psql -c "SELECT * FROM pg_stat_database;"
```

## 💾 Backup & Recovery

### 1. Database Backup

```bash
# Create backup script
nano /usr/local/bin/backup-db.sh

#!/bin/bash
BACKUP_DIR="/var/backups/postgresql"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="ai_document_master_prod"

mkdir -p $BACKUP_DIR
pg_dump -h localhost -U ai_doc_user $DB_NAME > $BACKUP_DIR/${DB_NAME}_${DATE}.sql

# Compress backup
gzip $BACKUP_DIR/${DB_NAME}_${DATE}.sql

# Keep only last 7 days
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

# Make executable
chmod +x /usr/local/bin/backup-db.sh

# Add to crontab
sudo crontab -e
# Add: 0 2 * * * /usr/local/bin/backup-db.sh
```

### 2. File Uploads Backup

```bash
# Backup uploads directory
rsync -av /var/uploads/ /var/backups/uploads/

# Or use tar
tar -czf /var/backups/uploads_$(date +%Y%m%d).tar.gz /var/uploads/
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Database Connection Failed
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Check connection
psql -h localhost -U ai_doc_user -d ai_document_master_prod

# Check logs
sudo tail -f /var/log/postgresql/postgresql-*.log
```

#### 2. Redis Connection Failed
```bash
# Check Redis status
sudo systemctl status redis

# Test connection
redis-cli -a your_password ping

# Check logs
sudo tail -f /var/log/redis/redis-server.log
```

#### 3. File Upload Issues
```bash
# Check permissions
ls -la /var/uploads/

# Fix permissions
sudo chown -R ai_doc_user:ai_doc_user /var/uploads/
sudo chmod -R 755 /var/uploads/
```

#### 4. High Memory Usage
```bash
# Check memory usage
free -h
ps aux --sort=-%mem | head

# Check Node.js memory
node --max-old-space-size=4096 src/server.js
```

### Performance Tuning

#### 1. PostgreSQL Tuning
```bash
# Edit postgresql.conf
sudo nano /etc/postgresql/*/main/postgresql.conf

# Memory settings
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB
```

#### 2. Redis Tuning
```bash
# Edit redis.conf
sudo nano /etc/redis/redis.conf

# Memory settings
maxmemory 256mb
maxmemory-policy allkeys-lru
```

#### 3. Node.js Tuning
```bash
# Increase memory limit
export NODE_OPTIONS="--max-old-space-size=4096"

# Use PM2 cluster mode
pm2 start src/server.js -i max --name "ai-document-master"
```

## 📞 Support

For production support and issues:

1. **Check logs first**: `tail -f logs/app.log`
2. **Verify environment**: Check all environment variables
3. **Test endpoints**: Use `/health` endpoint
4. **Database connectivity**: Verify PostgreSQL and Redis connections
5. **File permissions**: Check upload directory permissions

## 🎯 Next Steps

After successful deployment:

1. **Setup monitoring**: Implement application monitoring
2. **Configure alerts**: Setup error and performance alerts
3. **Performance testing**: Load test your API endpoints
4. **Security audit**: Regular security assessments
5. **Backup verification**: Test backup and recovery procedures

---

**🎉 Congratulations! Your AI Document Master backend is now production-ready!**
