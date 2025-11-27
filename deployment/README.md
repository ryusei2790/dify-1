# Dify Deployment for GCP Compute Engine

This directory contains all the necessary files and scripts to deploy Dify on Google Cloud Platform (GCP) Compute Engine.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Deployment](#deployment)
- [Management](#management)
- [Backup and Restore](#backup-and-restore)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

This deployment setup uses:
- **Infrastructure**: Terraform for IaC (Infrastructure as Code)
- **Instance Type**: e2-medium (2 vCPU, 4GB RAM)
- **OS**: Ubuntu 22.04 LTS
- **Container Runtime**: Docker with Docker Compose
- **SSL**: Let's Encrypt with automatic renewal
- **Database**: PostgreSQL 15
- **Cache**: Redis 6
- **Vector Database**: Weaviate

## ✅ Prerequisites

Before you begin, ensure you have:

1. **GCP Project** with billing enabled
2. **gcloud CLI** installed and configured
   ```bash
   # Install gcloud CLI
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL

   # Initialize and authenticate
   gcloud init
   gcloud auth login
   gcloud auth application-default login
   ```

3. **Terraform** installed (>= 1.0)
   ```bash
   # macOS
   brew install terraform

   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

4. **Domain name** (for SSL certificate)
5. **SSH keys** (optional, can use gcloud ssh)

## 🚀 Quick Start

```bash
# 1. Set your GCP project ID
export PROJECT_ID="your-gcp-project-id"
export ZONE="us-central1-a"
export INSTANCE_NAME="dify-server"

# 2. Generate secrets for production
cd deployment
./scripts/setup-secrets.sh

# 3. Edit .env.production with your domain
vim .env.production
# Update: DOMAIN_NAME, CERTBOT_EMAIL, and all *_URL variables

# 4. Configure Terraform
cd terraform
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
# Update: project_id, domain_name, email

# 5. Deploy
cd ..
./scripts/deploy.sh deploy
```

## 📖 Detailed Setup

### Step 1: Configure Environment Variables

Generate production secrets:

```bash
cd deployment
./scripts/setup-secrets.sh
```

This creates `.env.production` with secure random passwords. Edit it to add your domain:

```bash
vim .env.production
```

Update these values:
- `DOMAIN_NAME`: Your domain (e.g., dify.example.com)
- `CONSOLE_API_URL`: https://your-domain.com
- `CONSOLE_WEB_URL`: https://your-domain.com
- `SERVICE_API_URL`: https://your-domain.com
- `APP_API_URL`: https://your-domain.com
- `APP_WEB_URL`: https://your-domain.com
- `FILES_URL`: https://your-domain.com
- `CERTBOT_EMAIL`: your-email@example.com
- `WEB_API_CORS_ALLOW_ORIGINS`: https://your-domain.com
- `CONSOLE_CORS_ALLOW_ORIGINS`: https://your-domain.com

### Step 2: Configure Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
```

Required variables:
- `project_id`: Your GCP project ID
- `domain_name`: Your domain name
- `email`: Your email for Let's Encrypt

Optional variables:
- `region`: GCP region (default: us-central1)
- `zone`: GCP zone (default: us-central1-a)
- `machine_type`: Instance type (default: e2-medium)
- `boot_disk_size`: Boot disk size in GB (default: 50)
- `data_disk_size`: Data disk size in GB (default: 100)

### Step 3: Provision Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply
```

This will create:
- Compute Engine instance (e2-medium)
- Static external IP address
- Firewall rules (HTTP, HTTPS, SSH)
- Persistent disk for data storage

After provisioning, note the external IP address:
```bash
terraform output static_ip_address
```

### Step 4: Configure DNS

Point your domain to the instance IP address:
- Create an A record for your domain
- Point it to the static IP from Terraform output
- Wait for DNS propagation (can take up to 48 hours)

## 🚢 Deployment

### Deploy Dify

```bash
export PROJECT_ID="your-gcp-project-id"
export ZONE="us-central1-a"
export INSTANCE_NAME="dify-server"

./scripts/deploy.sh deploy
```

The deploy script will:
1. Check prerequisites
2. Wait for instance to be ready
3. Sync files to the instance
4. Start Docker containers
5. Display the instance IP and access URL

### Manual Deployment Steps (Alternative)

If you prefer manual deployment:

```bash
# SSH into the instance
gcloud compute ssh ubuntu@dify-server --zone=us-central1-a --project=your-project-id

# Clone or copy your Dify configuration
cd /opt/dify

# Copy docker configuration (if not already synced)
# ... copy files ...

# Start Dify
cd docker
docker compose up -d
```

## 🔧 Management

### Check Status

```bash
./scripts/deploy.sh status
```

### View Logs

```bash
# View all logs
./scripts/deploy.sh logs

# View specific service logs
./scripts/deploy.sh logs api
./scripts/deploy.sh logs nginx
```

### Restart Services

```bash
./scripts/deploy.sh restart
```

### Stop Services

```bash
./scripts/deploy.sh stop
```

### SSH into Instance

```bash
./scripts/deploy.sh ssh
```

### Get Instance IP

```bash
./scripts/deploy.sh ip
```

### Update Dify

```bash
# SSH into the instance
./scripts/deploy.sh ssh

# Pull latest images and restart
cd /opt/dify/docker
docker compose pull
docker compose up -d
```

## 💾 Backup and Restore

### Create Backup

```bash
export PROJECT_ID="your-gcp-project-id"
export ZONE="us-central1-a"
export INSTANCE_NAME="dify-server"

./scripts/backup.sh
```

This backs up:
- PostgreSQL database
- Docker volumes (uploaded files, etc.)
- Environment configuration

Backups are stored in `deployment/backups/` with timestamps.

### Restore from Backup

```bash
# SSH into the instance
./scripts/deploy.sh ssh

# Stop Dify
cd /opt/dify/docker
docker compose down

# Restore database
cat backup.sql | docker compose exec -T db_postgres psql -U postgres dify

# Restore volumes
tar xzf volumes_backup.tar.gz -C /opt/dify/docker/

# Restart Dify
docker compose up -d
```

### Automated Backups

Set up a cron job on the instance:

```bash
# On the remote instance
crontab -e

# Add daily backup at 2 AM
0 2 * * * /opt/dify/docker/docker-compose exec -T db_postgres pg_dump -U postgres dify > /mnt/dify-data/backups/dify_$(date +\%Y\%m\%d).sql
```

## 🐛 Troubleshooting

### Instance Not Accessible

Check firewall rules:
```bash
gcloud compute firewall-rules list --project=your-project-id
```

Verify instance is running:
```bash
gcloud compute instances list --project=your-project-id --filter="name=dify-server"
```

### SSL Certificate Issues

Check Certbot logs:
```bash
./scripts/deploy.sh ssh
docker compose logs nginx
```

Manually trigger certificate generation:
```bash
docker compose exec nginx certbot --nginx -d your-domain.com
```

### Database Connection Issues

Check database status:
```bash
./scripts/deploy.sh logs db_postgres
```

Verify database credentials in `.env`:
```bash
./scripts/deploy.sh ssh
cat /opt/dify/docker/.env | grep DB_
```

### Container Crashes

View container logs:
```bash
./scripts/deploy.sh logs api
./scripts/deploy.sh logs worker
```

Check container resource usage:
```bash
./scripts/deploy.sh ssh
docker stats
```

### Performance Issues

Monitor instance resources:
```bash
./scripts/deploy.sh ssh
htop
```

Consider upgrading instance type:
```bash
cd terraform
# Edit terraform.tfvars: machine_type = "e2-standard-4"
terraform apply
```

## 📚 Additional Resources

- [Dify Documentation](https://docs.dify.ai/)
- [GCP Compute Engine Docs](https://cloud.google.com/compute/docs)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

## 🔐 Security Best Practices

1. **Use strong passwords**: Generated by `setup-secrets.sh`
2. **Restrict SSH access**: Configure firewall rules to allow SSH only from specific IPs
3. **Enable Cloud Armor**: Protect against DDoS attacks
4. **Regular backups**: Schedule automated daily backups
5. **Update regularly**: Keep Dify and system packages up to date
6. **Monitor logs**: Set up log aggregation and alerting
7. **Use Secret Manager**: Store sensitive data in GCP Secret Manager

## 💰 Cost Estimation

Approximate monthly costs (us-central1):
- e2-medium instance: ~$25/month
- 50GB boot disk: ~$2/month
- 100GB data disk: ~$4/month
- Static IP: ~$3/month
- Network egress: Variable

**Total: ~$34/month** (excluding network egress)

For production workloads, consider:
- e2-standard-4 (4 vCPU, 16GB RAM): ~$100/month
- Cloud SQL for managed PostgreSQL
- Cloud Memorystore for managed Redis
- Cloud Load Balancing for high availability

## 📝 License

This deployment configuration is provided as-is. Dify itself is licensed under the Apache License 2.0.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
