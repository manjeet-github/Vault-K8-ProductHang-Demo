As a operator of the product, you will have to configure vault.
The producer workflow consists of 
The producer workflow requires few configuration as below ...
         1. Enable Secrets Engine - KV Secret
         2. Setup Data - Add some Secrets
         3. Configure Access - Create a policy

# Enable static KV Secrets Engine and store some static secret

```
vault secrets enable -path=internal kv-v2
vault kv put internal/database/config username="db-readonly-username" password="db-secret-password"
vault kv get internal/database/config

```  

# Create Vault policy to access the KV Secrets
```
vault policy write internal-webapp-policy - <<EOF
path "internal/data/database/config" {
  capabilities = ["read"]
}

path "k8-data-encryption/*" {
  capabilities = ["read", "create", "update", "list"]
}

vault policy list

vault policy read internal-webapp-policy
```



