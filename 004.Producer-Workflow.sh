#!/bin/sh

set -e

PATH=`pwd`/bin:$PATH:/usr/local/bin

if [ -f demo_env.sh ]; then
    . ./demo_env.sh
fi

clear
echo
echo "                      -: PRODUCER WORKFLOW :-     " 
echo "#------> The producer workflow requires few configuration as below ..."
echo "#------>          1. Enable Secrets Engine - KV Secret"
echo "#------>          2. Setup Data - Add some Secrets"
echo "#------>          3. Configure Access - Create a policy"
echo "_"

echo
read
echo "⇒  vault secrets enable -path=internal kv-v2"
sleep 2
vault secrets enable -path=internal kv-v2
echo

echo "_"
read
echo "⇒  vault kv put internal/database/config username=\"db-readonly-username\" password=\"db-secret-password\""
sleep 2
vault kv put internal/database/config username="db-readonly-username" password="db-secret-password"
echo

echo "_"
read
echo "⇒  vault kv get internal/database/config"
sleep 1
vault kv get internal/database/config
echo

echo "_"
read
echo "⇒  vault policy write internal-web-policy - <<EOF"
echo "> path \"internal/data/database/config\" {"
echo ">   capabilities = ["read"]"
echo "> }"
echo "> EOF"
echo "_"
read
vault policy write internal-webapp-policy - <<EOF
path "internal/data/database/config" {
  capabilities = ["read"]
}

path "k8-data-encryption/*" {
  capabilities = ["read", "create", "update", "list"]
}
EOF
echo

sleep 1
echo "⇒  vault policy list"
vault policy list
echo

sleep 1
echo "⇒  vault policy read internal-webapp-policy"
sleep 1
vault policy read internal-webapp-policy
echo "_"

read
echo
clear
