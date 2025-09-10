#!/bin/sh

# Start Vault server in dev mode
vault server -dev -dev-root-token-id=root -dev-listen-address=0.0.0.0:8200 &

# Wait for Vault to start
sleep 5

# In dev mode, Vault is already initialized and unsealed
# We just need to configure it
echo "Vault started in dev mode. Configuring..."

# Set Vault address
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

# In dev mode, KV v2 is already enabled at 'secret/'
# We don't need to enable it again

# Store database credentials in Vault
# For KV v2, we use 'kv put'
vault kv put secret/database/credentials \
  username="${DB_USER}" \
  password="${DB_PASSWORD}" \
  dbname="${DB_NAME}" \
  port="${DB_PORT}" \
  host=postgres

# Store Kafka credentials in Vault
vault kv put secret/kafka/credentials \
  bootstrap_servers=kafka:9092

echo "Vault has been configured!"
echo "========== Secret Path =========="
vault kv get secret/database/credentials
echo "========== Secret Path =========="
vault kv get secret/kafka/credentials

# Keep the container running
tail -f /dev/null
