#!/bin/bash
set -e

# Script to generate secure secrets for Dify production deployment
# This will create a .env.production file with generated secrets

echo "====================================="
echo "Dify Production Secrets Generator"
echo "====================================="
echo ""

DEPLOYMENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_TEMPLATE="$DEPLOYMENT_DIR/.env.production.example"
ENV_FILE="$DEPLOYMENT_DIR/.env.production"

# Check if .env.production already exists
if [ -f "$ENV_FILE" ]; then
    read -p ".env.production already exists. Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Copy template
cp "$ENV_TEMPLATE" "$ENV_FILE"

echo "Generating secure secrets..."

# Generate secrets
SECRET_KEY=$(openssl rand -hex 32)
DB_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-20)
REDIS_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-20)
WEAVIATE_API_KEY=$(openssl rand -hex 32)

# Replace placeholders in .env.production
sed -i.bak "s/SECRET_KEY=CHANGE_THIS_TO_A_RANDOM_SECRET_KEY/SECRET_KEY=$SECRET_KEY/" "$ENV_FILE"
sed -i.bak "s/DB_PASSWORD=CHANGE_THIS_DATABASE_PASSWORD/DB_PASSWORD=$DB_PASSWORD/" "$ENV_FILE"
sed -i.bak "s/REDIS_PASSWORD=CHANGE_THIS_REDIS_PASSWORD/REDIS_PASSWORD=$REDIS_PASSWORD/" "$ENV_FILE"
sed -i.bak "s/WEAVIATE_API_KEY=CHANGE_THIS_WEAVIATE_API_KEY/WEAVIATE_API_KEY=$WEAVIATE_API_KEY/" "$ENV_FILE"
sed -i.bak "s|CELERY_BROKER_URL=redis://:CHANGE_THIS_REDIS_PASSWORD@redis:6379/1|CELERY_BROKER_URL=redis://:$REDIS_PASSWORD@redis:6379/1|" "$ENV_FILE"

# Remove backup file
rm -f "$ENV_FILE.bak"

echo ""
echo "✅ Secrets generated successfully!"
echo ""
echo "⚠️  IMPORTANT: Please update the following in $ENV_FILE:"
echo "   - DOMAIN_NAME"
echo "   - CONSOLE_API_URL"
echo "   - CONSOLE_WEB_URL"
echo "   - SERVICE_API_URL"
echo "   - APP_API_URL"
echo "   - APP_WEB_URL"
echo "   - FILES_URL"
echo "   - CERTBOT_EMAIL"
echo "   - WEB_API_CORS_ALLOW_ORIGINS"
echo "   - CONSOLE_CORS_ALLOW_ORIGINS"
echo ""
echo "Generated secrets:"
echo "   SECRET_KEY: $SECRET_KEY"
echo "   DB_PASSWORD: $DB_PASSWORD"
echo "   REDIS_PASSWORD: $REDIS_PASSWORD"
echo "   WEAVIATE_API_KEY: $WEAVIATE_API_KEY"
echo ""
echo "⚠️  Keep these credentials secure and never commit them to version control!"
echo ""
