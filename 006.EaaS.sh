#!/bin/sh

set -e

PATH=`pwd`/bin:$PATH:/usr/local/bin

if [ -f demo_env.sh ]; then
    . ./demo_env.sh
fi

clear
echo
echo "                      -: EaaS WORKFLOW :-      " 
echo
echo "#------> The consumer workflow requires few configuration as apps are deployed ..."
echo "#------>          1. Enable Transit Secret"
echo "#------>          2. Add Policy to access the Transit endpoint"
echo "#------>          3. encrypt the data from the pod container"
echo "_"
read

echo "⇒ vault secrets enable  -path=k8-data-encryption transit"
echo "_"
read
vault secrets enable  -path=k8-data-encryption transit

sleep 1
echo "⇒  vault secrets list"
sleep 1
vault secrets list
echo

echo "Create a Keyring ..."
echo "_"
read
echo "⇒  vault write -f k8-data-encryption/keys/webapp-1"
vault write -f k8-data-encryption/keys/webapp-1
echo "_"
read

echo "Add a policy to access the transit endpoint"
sleep 1
echo "⇒  vault policy read internal-webapp-policy"
sleep 1
vault policy read internal-webapp-policy
echo "_"
read

sleep 2
echo "Let's encrypt some data.. plaintext is base64"
echo "⇒  kubectl exec \$(kubectl get pods | grep webapp-1 | awk {'print \$1}') -- curl --header "X-Vault-Token: \$VAULT_TOKEN" --request POST --data '{"plaintext": "TWFuamVldCBTaW5naAo="}'  http://external-vault:8200/v1/k8-data-encryption/encrypt/webapp-1 | jq"
echo "_"
read
kubectl exec $(kubectl get pods | grep webapp-1 | awk {'print $1}') -c app -- curl -s --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data '{"plaintext": "TWFuamVldCBTaW5naAo="}'  http://external-vault:8200/v1/k8-data-encryption/encrypt/webapp-1 | jq -r 

export CIPHERTEXT=$(kubectl exec $(kubectl get pods | grep webapp-1 | awk {'print $1}') -c app -- curl -s --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data '{"plaintext": "TWFuamVldCBTaW5naAo="}'  http://external-vault:8200/v1/k8-data-encryption/encrypt/webapp-1 | cut -d :  -f7 -f8 -f9 | cut -d , -f1 | sed 's/"//g' )
json_string="{\"ciphertext\": \""$CIPHERTEXT"\"}"
echo $json_string > payload.json
echo

#echo "Let's decrypt some data.. using ciphertext = "$CIPHERTEXT
#echo "⇒  kubectl exec \$(kubectl get pods | grep webapp-1 | awk {'print \$1}') -c app -- curl --header \"X-Vault-Token: $VAULT_TOKEN\" --request POST --data $json_string http://external-vault:8200/v1/k8-data-encryption/decrypt/webapp-1 | jq"
#echo "_"
#read
#kubectl exec $(kubectl get pods | grep webapp-1 | awk {'print $1}') -c app -- curl -s --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data @payload.json  http://external-vault:8200/v1/k8-data-encryption/decrypt/webapp-1 | jq

#rm payload.json

echo
echo "_"
read

echo "☼ END DEMO"
read
echo
