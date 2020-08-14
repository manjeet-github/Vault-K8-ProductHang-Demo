#!/bin/sh

set -e

PATH=`pwd`/bin:$PATH:/usr/local/bin

if [ -f demo_env.sh ]; then
    . ./demo_env.sh
fi

clear
echo
echo "#------> Configure Vault-Token-Reviewer Service Account ..."
echo "⇒  cat yaml-files/vault-token-reviewer.yaml"
cat yaml-files/vault-token-reviewer.yaml

echo "_"
read
echo "⇒  kubectl create -f yaml-files/vault-token-reviewer.yaml"
sleep 2
kubectl create -f yaml-files/vault-token-reviewer.yaml
echo

sleep 2
echo "⇒  kubectl get sa"
kubectl get sa
echo

echo "_"
read
echo
clear
