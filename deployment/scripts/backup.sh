#!/bin/bash
set -e

# Dify backup script for GCP Compute Engine
# This script creates backups of database and volumes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOYMENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Configuration
INSTANCE_NAME="${INSTANCE_NAME:-dify-server}"
ZONE="${ZONE:-us-central1-a}"
PROJECT_ID="${PROJECT_ID:-}"
REMOTE_USER="${REMOTE_USER:-ubuntu}"
REMOTE_DIR="/opt/dify"
BACKUP_DIR="$DEPLOYMENT_DIR/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

print_info "Starting backup process..."

# Backup database
print_info "Backing up PostgreSQL database..."
gcloud compute ssh "$REMOTE_USER@$INSTANCE_NAME" \
    --zone="$ZONE" \
    --project="$PROJECT_ID" \
    --command="cd $REMOTE_DIR/docker && docker compose exec -T db_postgres pg_dump -U postgres dify" \
    > "$BACKUP_DIR/dify_db_$TIMESTAMP.sql"

print_info "Database backup saved to: $BACKUP_DIR/dify_db_$TIMESTAMP.sql"

# Backup volumes
print_info "Backing up Docker volumes..."
gcloud compute ssh "$REMOTE_USER@$INSTANCE_NAME" \
    --zone="$ZONE" \
    --project="$PROJECT_ID" \
    --command="cd $REMOTE_DIR/docker && tar czf - volumes" \
    > "$BACKUP_DIR/dify_volumes_$TIMESTAMP.tar.gz"

print_info "Volumes backup saved to: $BACKUP_DIR/dify_volumes_$TIMESTAMP.tar.gz"

# Backup .env file
print_info "Backing up environment configuration..."
gcloud compute scp \
    "$REMOTE_USER@$INSTANCE_NAME:$REMOTE_DIR/docker/.env" \
    "$BACKUP_DIR/dify_env_$TIMESTAMP" \
    --zone="$ZONE" \
    --project="$PROJECT_ID"

print_info "Environment backup saved to: $BACKUP_DIR/dify_env_$TIMESTAMP"

print_info ""
print_info "Backup completed successfully!"
print_info "Backup location: $BACKUP_DIR"
print_info ""
print_info "Files created:"
print_info "  - dify_db_$TIMESTAMP.sql"
print_info "  - dify_volumes_$TIMESTAMP.tar.gz"
print_info "  - dify_env_$TIMESTAMP"
print_info ""

# Clean up old backups (keep last 7 days)
print_info "Cleaning up old backups (keeping last 7 days)..."
find "$BACKUP_DIR" -name "dify_*" -type f -mtime +7 -delete
print_info "Cleanup completed."
