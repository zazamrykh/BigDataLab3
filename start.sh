#!/bin/bash

# Script to start the application with environment variables passed as parameters
# This script launches services separately to ensure proper isolation of environment variables

# Default values
DB_USER="postgres"
DB_PASSWORD="postgres"
DB_NAME="reviewdb"
DB_PORT="5432"
VAULT_ADDR="http://vault:8200"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --db-user=*)
      DB_USER="${1#*=}"
      shift
      ;;
    --db-password=*)
      DB_PASSWORD="${1#*=}"
      shift
      ;;
    --db-name=*)
      DB_NAME="${1#*=}"
      shift
      ;;
    --db-port=*)
      DB_PORT="${1#*=}"
      shift
      ;;
    --vault-addr=*)
      VAULT_ADDR="${1#*=}"
      shift
      ;;
    --env-file=*)
      ENV_FILE="${1#*=}"
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --db-user=USER         Database user (default: postgres)"
      echo "  --db-password=PASSWORD Database password (default: postgres)"
      echo "  --db-name=NAME         Database name (default: reviewdb)"
      echo "  --db-port=PORT         Database port (default: 5432)"
      echo "  --vault-addr=ADDR      Vault address (default: http://vault:8200)"
      echo "  --env-file=FILE        Environment file to use"
      echo "  --help                 Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# If env file is provided, use it
if [ -n "$ENV_FILE" ] && [ -f "$ENV_FILE" ]; then
  echo "Using environment file: $ENV_FILE"
  # Start docker-compose with env file
  docker compose --env-file "$ENV_FILE" up -d
  echo "Application started successfully with environment file!"
else
  echo "Starting services separately with appropriate environment variables..."

  # Step 1: Start Vault with database credentials
  # Vault needs DB credentials to store them in the vault
  echo "Starting Vault service..."
  DB_USER=$DB_USER \
  DB_PASSWORD=$DB_PASSWORD \
  DB_NAME=$DB_NAME \
  DB_PORT=$DB_PORT \
  docker compose up -d vault

  # Wait for Vault to be ready
  echo "Waiting for Vault to be ready..."
  for i in {1..30}; do
    if curl -s http://localhost:8200/v1/sys/health | grep -q '"initialized":true'; then
      echo "Vault is ready!"
      break
    fi
    echo "Waiting for Vault to initialize... ($i/30)"
    sleep 2
    if [ $i -eq 30 ]; then
      echo "Vault failed to initialize in time. Check logs with: docker compose logs vault"
      exit 1
    fi
  done

  # Step 2: Start PostgreSQL with initialization variables
  # PostgreSQL needs these variables only for initialization
  echo "Starting PostgreSQL service..."
  POSTGRES_USER=$DB_USER \
  POSTGRES_PASSWORD=$DB_PASSWORD \
  POSTGRES_DB=$DB_NAME \
  docker compose up -d postgres

  # Wait for PostgreSQL to be ready
  echo "Waiting for PostgreSQL to be ready..."
  for i in {1..30}; do
    if docker compose exec postgres pg_isready -U $DB_USER > /dev/null 2>&1; then
      echo "PostgreSQL is ready!"
      break
    fi
    echo "Waiting for PostgreSQL to initialize... ($i/30)"
    sleep 2
    if [ $i -eq 30 ]; then
      echo "PostgreSQL failed to initialize in time. Check logs with: docker compose logs postgres"
      exit 1
    fi
  done

  # Step 3: Start the application without database credentials
  # App will get credentials from Vault
  echo "Starting application service..."
  docker compose up -d app

  echo "All services started successfully!"
fi

echo "You can access the API at http://localhost:8000"
echo "You can access Vault at http://localhost:8200"
