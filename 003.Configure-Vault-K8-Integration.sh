#!/bin/sh

set -e

PATH=`pwd`/bin:$PATH:/usr/local/bin

if [ -f demo_env.sh ]; then
    . ./demo_env.sh
fi

clear
echo
echo "#------> Configure Vault for Vault-K8 Integration ..."
echo "#------> This integration needs three params for the configuration ..."
echo "#------> 		1. K8 Host URL"
echo "#------> 		2. K8 CA Cert for the Kube-API"
echo "#------> 		3. K8 Service Account Secret (vault-token-reviewer SA JWT)"
echo
echo
echo "#------> 		1. K8 Host URL"
echo "⇒  kubectl cluster-info"
echo "_"
read
kubectl cluster-info
export K8_HOST=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.server}')
echo
echo "export K8_HOST="$K8_HOST
echo

echo "_"
read
echo "#------> 2. K8 CA Cert for the Kube-API"
echo "⇒  kubectl get secret \$(kubectl get serviceaccount vault-reviewer -o json | jq -r '.secrets[0].name') -o jsonpath="{.data['ca\.crt']}" | base64 --decode > k8-ca.crt"
echo "_"
read
echo "⇒  kubectl get secret $(kubectl get serviceaccount vault-reviewer -o json | jq -r '.secrets[0].name') -o jsonpath="{.data['ca\.crt']}" | base64 --decode > k8-ca.crt"
sleep 2
kubectl get secret \
  $(kubectl get serviceaccount vault-reviewer -o json | jq -r '.secrets[0].name') \
  -o jsonpath="{.data['ca\.crt']}" | base64 --decode > k8-ca.crt

echo
echo "⇒  cat k8-ca.crt"
cat k8-ca.crt
echo "_"


read
echo "#------> 3. K8 Service Account Secret (vault-token-reviewer SA JWT)"
echo "⇒  kubectl get secret \
  $(kubectl get serviceaccount vault-reviewer -o json | jq -r '.secrets[0].name') \
  -o json | jq -r '.data .token' | base64 -D - "
sleep 2
echo
export VAULT_TOKEN_REVIEWER_JWT=$(kubectl get secret \
  $(kubectl get serviceaccount vault-reviewer -o json | jq -r '.secrets[0].name') \
  -o json | jq -r '.data .token' | base64 -D -)

echo "export VAULT_TOKEN_REVIEWER_JWT="$VAULT_TOKEN_REVIEWER_JWT

echo "_"
echo
read
echo "⇒  cat yaml-files/vault-k8-integration.config"
cat yaml-files/vault-k8-integration.config
echo "_"
read
/usr/local/bin/vault auth enable kubernetes
/usr/local/bin/vault write auth/kubernetes/config \
    token_reviewer_jwt="${VAULT_TOKEN_REVIEWER_JWT}"  \
    kubernetes_host="${K8_HOST}" \
    kubernetes_ca_cert=@k8-ca.crt

echo
echo "Read the configured K8-Auth in Vault"
echo "/usr/local/bin/vault read auth/kubernetes/config"
echo "_"
read
/usr/local/bin/vault read auth/kubernetes/config

read
echo
clear
