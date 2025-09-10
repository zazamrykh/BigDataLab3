#!/bin/sh
set -e

# Wait for Vault to start
sleep 5

# Set Vault address
export VAULT_ADDR='http://127.0.0.1:8200'  # локальный адрес внутри контейнера Vault [1]

# Initialize Vault with 1 key share and 1 key threshold
vault operator init -key-shares=1 -key-threshold=1 > /vault/data/init.txt  # инициализация и вывод в файл [1]

# Extract root token and unseal key
VAULT_UNSEAL_KEY=$(grep 'Unseal Key 1:' /vault/data/init.txt | awk '{print $NF}')  # парсинг ключа [1]
VAULT_ROOT_TOKEN=$(grep 'Initial Root Token:' /vault/data/init.txt | awk '{print $NF}')  # парсинг токена [1]

# Save tokens to files for later use
echo "$VAULT_UNSEAL_KEY" > /vault/data/unseal_key.txt  # сохранить unseal key [1]
echo "$VAULT_ROOT_TOKEN" > /vault/data/root_token.txt  # сохранить root token [1]

# Unseal Vault
vault operator unseal "$VAULT_UNSEAL_KEY"  # разгерметизация [1]

# Authenticate non-interactively by exporting token
export VAULT_TOKEN="$VAULT_ROOT_TOKEN"  # вместо интерактивного 'vault login' [1]

# Enable the KV secrets engine (v2)
vault secrets enable -version=2 kv || true  # идемпотентно включить kv v2 [2]

# Create a policy for our application (read access to kv v2 paths via API)
cat > /tmp/app-policy.hcl << 'EOF'
path "kv/data/database/*" {
  capabilities = ["read"]
}
path "kv/data/kafka/*" {
  capabilities = ["read"]
}
EOF
vault policy write app-policy /tmp/app-policy.hcl  # записать политику [2]

# Create an app token with the app-policy
vault token create -policy=app-policy -format=json | jq -r '.auth.client_token' > /vault/data/app_token.txt  # без интерактива [1]

# Store database credentials in Vault (KV v2 via CLI path 'kv/...')
vault kv put kv/database/credentials \
  username="${DB_USER}" \
  password="${DB_PASSWORD}" \
  dbname="${DB_NAME}" \
  port="${DB_PORT}" \
  host=postgres  # запись секрета в kv/database/credentials [2]

# Store Kafka credentials in Vault
vault kv put kv/kafka/credentials \
  bootstrap_servers=kafka:9092  # запись секрета для Kafka [2]

echo "Vault has been initialized and configured!"  # статус [1]
echo "App token: $(cat /vault/data/app_token.txt)"  # показать app token [1]
