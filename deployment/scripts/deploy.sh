#!/bin/bash
set -e

# Dify deployment script for GCP Compute Engine
# This script deploys Dify to a remote Compute Engine instance

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOYMENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$DEPLOYMENT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
INSTANCE_NAME="${INSTANCE_NAME:-dify-server}"
ZONE="${ZONE:-us-central1-a}"
PROJECT_ID="${PROJECT_ID:-}"
REMOTE_USER="${REMOTE_USER:-ubuntu}"
REMOTE_DIR="/opt/dify"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."

    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi

    if ! command -v terraform &> /dev/null; then
        print_warn "Terraform is not installed. Infrastructure provisioning will be skipped."
    fi

    if [ -z "$PROJECT_ID" ]; then
        print_error "PROJECT_ID is not set. Please set it with: export PROJECT_ID=your-gcp-project-id"
        exit 1
    fi

    print_info "Prerequisites check passed."
}

# Function to provision infrastructure with Terraform
provision_infrastructure() {
    print_info "Provisioning infrastructure with Terraform..."

    cd "$DEPLOYMENT_DIR/terraform"

    if [ ! -f "terraform.tfvars" ]; then
        print_error "terraform.tfvars not found. Please create it from terraform.tfvars.example"
        exit 1
    fi

    terraform init
    terraform plan

    read -p "Apply Terraform changes? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply
    else
        print_warn "Terraform apply skipped."
    fi

    cd "$SCRIPT_DIR"
}

# Function to wait for instance to be ready
wait_for_instance() {
    print_info "Waiting for instance to be ready..."

    max_attempts=30
    attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if gcloud compute ssh "$REMOTE_USER@$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" \
            --command="echo 'Instance is ready'" &> /dev/null; then
            print_info "Instance is ready!"
            return 0
        fi

        attempt=$((attempt + 1))
        print_info "Waiting for instance... (attempt $attempt/$max_attempts)"
        sleep 10
    done

    print_error "Instance did not become ready in time."
    exit 1
}

# Function to sync files to remote instance
sync_files() {
    print_info "Syncing files to remote instance..."

    # Create remote directory
    gcloud compute ssh "$REMOTE_USER@$INSTANCE_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" \
        --command="sudo mkdir -p $REMOTE_DIR && sudo chown -R $REMOTE_USER:$REMOTE_USER $REMOTE_DIR"

    # Copy docker directory
    print_info "Copying Docker configuration..."
    gcloud compute scp --recurse \
        "$PROJECT_ROOT/docker" \
        "$REMOTE_USER@$INSTANCE_NAME:$REMOTE_DIR/" \
        --zone="$ZONE" \
        --project="$PROJECT_ID"

    # Copy production .env if exists
    if [ -f "$DEPLOYMENT_DIR/.env.production" ]; then
        print_info "Copying production environment file..."
        gcloud compute scp \
            "$DEPLOYMENT_DIR/.env.production" \
            "$REMOTE_USER@$INSTANCE_NAME:$REMOTE_DIR/docker/.env" \
            --zone="$ZONE" \
            --project="$PROJECT_ID"
    else
        print_warn ".env.production not found. Using default .env.example"
        gcloud compute ssh "$REMOTE_USER@$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" \
            --command="cd $REMOTE_DIR/docker && cp .env.example .env"
    fi

    print_info "Files synced successfully."
}

# Function to start Dify on remote instance
start_dify() {
    print_info "Starting Dify on remote instance..."

    gcloud compute ssh "$REMOTE_USER@$INSTANCE_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" \
        --command="cd $REMOTE_DIR/docker && docker compose pull && docker compose up -d"

    print_info "Dify started successfully!"
}

# Function to show status
show_status() {
    print_info "Checking Dify status..."

    gcloud compute ssh "$REMOTE_USER@$INSTANCE_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" \
        --command="cd $REMOTE_DIR/docker && docker compose ps"
}

# Function to show logs
show_logs() {
    local service="${1:-}"

    if [ -z "$service" ]; then
        print_info "Showing all logs..."
        gcloud compute ssh "$REMOTE_USER@$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" \
            --command="cd $REMOTE_DIR/docker && docker compose logs --tail=50"
    else
        print_info "Showing logs for $service..."
        gcloud compute ssh "$REMOTE_USER@$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" \
            --command="cd $REMOTE_DIR/docker && docker compose logs --tail=50 $service"
    fi
}

# Function to stop Dify
stop_dify() {
    print_info "Stopping Dify..."

    gcloud compute ssh "$REMOTE_USER@$INSTANCE_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" \
        --command="cd $REMOTE_DIR/docker && docker compose down"

    print_info "Dify stopped."
}

# Function to get instance IP
get_instance_ip() {
    local ip=$(gcloud compute instances describe "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" \
        --format="get(networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null)

    if [ -n "$ip" ]; then
        print_info "Instance IP: $ip"
        echo "$ip"
    else
        print_error "Could not get instance IP"
        return 1
    fi
}

# Main deployment function
deploy() {
    print_info "Starting Dify deployment to GCP Compute Engine..."

    check_prerequisites

    # Ask if user wants to provision infrastructure
    if command -v terraform &> /dev/null; then
        read -p "Provision infrastructure with Terraform? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            provision_infrastructure
        fi
    fi

    wait_for_instance
    sync_files
    start_dify

    print_info ""
    print_info "====================================="
    print_info "Deployment completed successfully!"
    print_info "====================================="
    print_info ""

    local ip=$(get_instance_ip)
    if [ -n "$ip" ]; then
        print_info "Access Dify at: http://$ip"
        print_info "After DNS configuration: https://your-domain.com"
    fi

    print_info ""
    print_info "Next steps:"
    print_info "1. Point your domain DNS to: $ip"
    print_info "2. Wait for DNS propagation"
    print_info "3. SSL certificate will be auto-generated on first HTTPS access"
    print_info ""
}

# Parse command line arguments
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    status)
        check_prerequisites
        show_status
        ;;
    logs)
        check_prerequisites
        show_logs "${2:-}"
        ;;
    stop)
        check_prerequisites
        stop_dify
        ;;
    restart)
        check_prerequisites
        stop_dify
        sleep 5
        start_dify
        ;;
    ssh)
        check_prerequisites
        gcloud compute ssh "$REMOTE_USER@$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID"
        ;;
    ip)
        check_prerequisites
        get_instance_ip
        ;;
    *)
        echo "Usage: $0 {deploy|status|logs [service]|stop|restart|ssh|ip}"
        echo ""
        echo "Commands:"
        echo "  deploy   - Deploy Dify to GCP Compute Engine"
        echo "  status   - Show status of Dify services"
        echo "  logs     - Show logs (optionally specify service name)"
        echo "  stop     - Stop Dify services"
        echo "  restart  - Restart Dify services"
        echo "  ssh      - SSH into the instance"
        echo "  ip       - Get instance IP address"
        exit 1
        ;;
esac
