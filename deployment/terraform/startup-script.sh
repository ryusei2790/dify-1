#!/bin/bash
set -e

# Startup script for Dify on GCP Compute Engine
# This script is executed when the instance first starts

echo "Starting Dify setup on GCP Compute Engine..."

# Update system packages
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker ubuntu
    rm get-docker.sh
fi

# Install Docker Compose
if ! command -v docker compose &> /dev/null; then
    echo "Installing Docker Compose..."
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
        -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
fi

# Format and mount data disk
if [ ! -d "/mnt/dify-data" ]; then
    echo "Setting up data disk..."
    mkdir -p /mnt/dify-data

    # Check if disk is already formatted
    if ! blkid /dev/sdb; then
        mkfs.ext4 -F /dev/sdb
    fi

    # Add to fstab if not already present
    if ! grep -q "/dev/sdb" /etc/fstab; then
        echo "/dev/sdb /mnt/dify-data ext4 defaults,nofail 0 2" >> /etc/fstab
    fi

    mount -a
    chown -R ubuntu:ubuntu /mnt/dify-data
fi

# Create application directory
mkdir -p /opt/dify
chown -R ubuntu:ubuntu /opt/dify

# Clone Dify repository (optional - can deploy from local)
# cd /opt/dify
# git clone https://github.com/langgenius/dify.git .

# Create symlink for data directory
ln -sf /mnt/dify-data /opt/dify/volumes

echo "Dify setup completed successfully!"
echo "Please configure your .env file and start Docker Compose manually"
echo ""
echo "Next steps:"
echo "1. Point your domain ${domain_name} to this instance's IP"
echo "2. Copy your Dify configuration to /opt/dify"
echo "3. Configure .env file with your settings"
echo "4. Run: cd /opt/dify/docker && docker compose up -d"
