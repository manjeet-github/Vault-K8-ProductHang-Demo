#!/bin/sh

set -e

PATH=`pwd`/bin:$PATH:/usr/local/bin

if [ -f demo_env.sh ]; then
    . ./demo_env.sh
fi

clear
echo
echo "                      -: CONSUMER WORKFLOW :-      " 
echo
echo "#------> The consumer workflow requires few configuration as apps are deployed ..."
echo "#------>          1. Create k8 service account for Application"
echo "#------>          2. Configure K8 Auth role in Vault"
echo "#------>          3. Add Annotations to the app deployment yaml"
echo "#------>          4. Deploy your app"
echo

echo "⇒  cat yaml-files/webapp-1-service-account.yaml"
echo "☼"
read
cat yaml-files/webapp-1-service-account.yaml

echo "☼"
read
echo "⇒  kubectl apply -f yaml-files/webapp-1-service-account.yaml"
sleep 2
kubectl apply -f yaml-files/webapp-1-service-account.yaml
echo

sleep 2
echo "⇒  kubectl get serviceaccounts"
kubectl get serviceaccounts
echo

echo "☼"
read
echo "#------> Create Vault-K8-Auth Role for the app "
echo "⇒  vault write auth/kubernetes/role/internal-webapp-role \ "
echo "     bound_service_account_names=internal-webapp-sa \ "
echo "     bound_service_account_namespaces=default \ "
echo "     policies=internal-webapp-policy \ "
echo "     ttl=1h "
echo "☼"
read
vault write auth/kubernetes/role/internal-webapp-role \
  bound_service_account_names=internal-webapp-sa \
  bound_service_account_namespaces=default \
  policies=internal-webapp-policy \
  ttl=1h 
echo

sleep 2
echo "⇒  vault read auth/kubernetes/role/internal-webapp-role"
vault read auth/kubernetes/role/internal-webapp-role
echo

echo "☼"
read
echo "#------> let's deploy the app ... "
echo "⇒  cat yaml-files/deploy-k8-webapp-1.yaml"
cat yaml-files/deploy-k8-webapp-1.yaml
echo
sleep 5
echo "⇒  kubectl apply -f yaml-files/deploy-k8-webapp-1.yaml"
echo "☼"
read
kubectl apply -f yaml-files/deploy-k8-webapp-1.yaml

sleep 2
echo
echo "⇒  kubectl exec $(kubectl get pods | grep webapp-1 | awk {'print $1}') -- curl -s http://external-vault:8200/v1/sys/seal-status | jq"
echo "☼"
read
kubectl exec $(kubectl get pods | grep webapp-1 | awk {'print $1}') -- curl -s http://external-vault:8200/v1/sys/seal-status | jq
echo
echo "☼"
read

echo
echo "#------> Check if application pod is deployed & running ..."
echo "⇒  kubectl get pods"
sleep 2
kubectl get pods
echo

echo "#------> let's deploy the *PATCH* ... "
echo "⇒  cat yaml-files/deploy-k8-webapp-1-patch.yaml"
cat yaml-files/deploy-k8-webapp-1-patch.yaml
echo
sleep 10
echo "⇒  kubectl patch deployment webapp-1 --patch \"\$(cat yaml-files/deploy-k8-webapp-1-patch.yaml)\""
echo "☼"
read
kubectl patch deployment webapp-1 --patch "$(cat yaml-files/deploy-k8-webapp-1-patch.yaml)"
echo

sleep 2
echo "#------> Check if application and vault-agent containers is deployed by injector ..."
echo "⇒  kubectl get pods"
sleep 2
kubectl get pods
echo

echo "☼"
read
echo "#------> Check vaultAgent-side-car logs ..."
echo "⇒  kubectl logs \$(kubectl get pod -l app=vault-inject-secrets-demo -o jsonpath=\"{.items[0].metadata.name}\")  --container vault-agent"
sleep 2
kubectl logs \
    $(kubectl get pod -l app=vault-inject-secrets-demo -o jsonpath="{.items[0].metadata.name}") \
    --container vault-agent
echo

echo "☼"
read
echo "#------> Validation: ls -l on the pod container ..."
echo "⇒  kubectl exec \$(kubectl get pod -l app=vault-inject-secrets-demo -o jsonpath=\"{.items[0].metadata.name}\")  -c app -- ls -lt /vault/secrets"
echo "☼"
read
kubectl exec \
    $(kubectl get pod -l app=vault-inject-secrets-demo -o jsonpath="{.items[0].metadata.name}") \
    -c app -- ls -lt /vault/secrets;echo;echo

echo "☼"
read
echo "#------> Validate if we have the secrets in the pod/container ..."
echo "⇒  kubectl exec \$(kubectl get pod -l app=vault-inject-secrets-demo -o jsonpath=\"{.items[0].metadata.name}\")  -c app -- cat /vault/secrets/database-config.txt"
echo "☼"
read
kubectl exec \
    $(kubectl get pod -l app=vault-inject-secrets-demo -o jsonpath="{.items[0].metadata.name}") \
    -c app -- cat /vault/secrets/database-config.txt;echo;echo

echo "☼ END DEMO"
read
echo
clear
