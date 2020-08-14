#!/bin/bash

# Initialize Vault
echo "[TASK 4] Initialize Vault with HSM..................\n"
set -e

export VAULT_ADDR=http://127.0.0.1:8200

if [ ! -f "/opt/vault/config/vault.init.data" ]; then
  logger "$0 - Initializing Vault"
  vault operator init -recovery-shares=1 -recovery-threshold=1 | tee /opt/vault/config/vault.init.data > /dev/null
  echo "Recovery keys and Root Token stored in .opt.vault.config.vault.init.data"
  echo "COMPLETED --> Vault initialized"

else
  echo "Vault already initialized"
  logger "$0 - Vault already initialized"
fi

echo "Vault setup complete"
logger "$0 - Vault setup complete"

echo "Installing Vault licenses"
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=$(cat /opt/vault/config/vault.init.data | grep Initial | awk '{print $4}')
/opt/vault/bin/vault write sys/license text=$(cat /opt/vault/bin/vault.lic)

tee -a /root/.bash_profile <<EOF
export VAULT_TOKEN=$(cat /opt/vault/config/vault.init.data | grep Initial | awk '{print $4}')
export VAULT_ADDR=http://127.0.0.1:8200
EOF

vault status

echo "---------------------------------------------------------------------\n"
sudo cat /opt/vault/config/vault.init.data
echo "-------------- VAULT_ADDR=http://localhost:38200 --------------------\n"
echo "---------------------------------------------------------------------\n"
