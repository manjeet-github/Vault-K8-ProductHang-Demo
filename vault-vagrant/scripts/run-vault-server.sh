#!/bin/sh -l

# Run Vault server
echo -e "vault server -config=/vault/config/vault-config.hcl" >> /root/.bash_history
vault server -config=/vault/config/vault-config.hcl -log-level=debug > /vault/logs/vault.log 2>&1 &

# Sleep 15 seconds
sleep 15

# Initialize Vault server
echo -e "vault operator init -key-shares=1 -key-threshold=1" >> /root/.bash_history
vault operator init -key-shares=1 -key-threshold=1 > init.log

# Extract root token and unseal key from init.log
token=$(sed -n 3p init.log | cut -d':' -f2 | cut -d' ' -f2)
unseal_key=$(sed -n 1p init.log | cut -d':' -f2 | cut -d' ' -f2)

# Write token to /root/token
echo $token > /root/token

# Write unseal key to /root/unseal_key
echo $unseal_key > /root/unseal_key

# Export VAULT_TOKEN
echo -e "export VAULT_TOKEN=$token" >> /root/.bash_history
export VAULT_TOKEN=$token

# Unseal Vault server
echo -e "vault operator unseal $unseal_key" >> /root/.bash_history
vault operator unseal $unseal_key

exit 0
