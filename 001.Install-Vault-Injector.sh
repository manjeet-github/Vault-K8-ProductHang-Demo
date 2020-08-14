#!/bin/sh

set -e

PATH=`pwd`/bin:$PATH:/usr/local/bin

if [ -f demo_env.sh ]; then
    . ./demo_env.sh
fi

clear
echo
echo "⇒  helm version"
echo 
sleep 2
helm version

echo "_"
read
echo "#------> Add hashicorp helm repo ..."
echo "⇒  helm repo add hashicorp https://helm.releases.hashicorp.com"
echo 
sleep 2
helm repo add hashicorp https://helm.releases.hashicorp.com
echo

echo "_"
read
echo "#------> List available releases ..."
echo "⇒  helm search repo hashicorp/vault -l"
echo 
sleep 2
helm search repo hashicorp/vault -l
echo

echo "_"
read
echo "#------> List installed helm charts ..."
echo "⇒  helm list"
echo
sleep 2
helm list
echo

echo "_"
read
echo "#------> Install Vault-Injector pointing to external Vault Server ..."
echo "#------> This is Dry-Run ..."
echo "⇒  helm install vault hashicorp/vault --set \"injector.externalVaultAddr=http://external-vault:8200\" --dry-run | grep \"^# Source\""
echo
sleep 3
helm install vault hashicorp/vault --set "injector.externalVaultAddr=http://external-vault:8200" --dry-run | grep "^# Source"
echo

echo "_"
read
echo "#------> Install Vault-Injector pointing to external Vault Server ..."
echo "⇒  helm install vault hashicorp/vault --set \"injector.externalVaultAddr=http://external-vault:8200\" "
helm install vault hashicorp/vault --set "injector.externalVaultAddr=http://external-vault:8200" 

echo "_"
read
echo "#------> List installed helm charts ..."
echo "⇒  helm list"
echo 
sleep 1
helm list
echo

echo "_"
read
clear
echo
echo "#------> Configure external-vault gress service ..."
echo "⇒  cat yaml-files/deploy-vault-external-service.yaml"
echo 
cat yaml-files/deploy-vault-external-service.yaml
echo "_"
read
kubectl apply -f yaml-files/deploy-vault-external-service.yaml
echo "_"

read
echo "#------> Check if vault-injector pod is installed & running ..."
echo "⇒  kubectl get pods"
echo
kubectl get pods
echo

echo "#------> Check if vault-injector service account is created ..."
echo "⇒  kubectl get sa"
echo
kubectl get sa 
echo

echo 
echo "#------> Check if external-vault service is created ..."
echo "⇒  kubectl get services"
echo 
kubectl get services
echo

echo
echo "_"
read
echo
clear
