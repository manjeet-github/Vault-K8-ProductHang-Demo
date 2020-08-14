As a consumer of Vault, you will mostly deploy application which needs secrets.
When deploying an app on kubernetes, your app will need a service account, a vault role and some annotations added to your app deployment yaml.

The consumer workflow requires few configuration as apps are deployed ...
          1. Create k8 service account for Application
          2. Configure K8 Auth role in Vault
          3. Add Annotations to the app deployment yaml
          4. Deploy your app


# Create Service Account for your app.

```
⇒  cat yaml-files/webapp-1-service-account.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: internal-webapp-sa
  labels:
    app: vault-injector-secrets-demo

kubectl apply -f yaml-files/webapp-1-service-account.yaml

kubectl get serviceaccounts

This service account does not need any RBAC permissions.

# Validate the SA accounts are created

⇒  kubectl get sa
NAME             SECRETS   AGE
default          1         4h32m
vault-auth       1         6s
vault-reviewer   1         13s
```  

# Configure role for the application in Vault. (Vault K8-Auth Role)
```
vault write auth/kubernetes/role/internal-webapp-role \
  bound_service_account_names=internal-webapp-sa \
  bound_service_account_namespaces=default \
  policies=internal-webapp-policy \
  ttl=1h

vault read auth/kubernetes/role/internal-webapp-role

vault policy read internal-webapp-policy
```

## - Deploy an app to use external Vault to get secrets.
```
⇒  cat 03-deploy-devweb-app.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: internal-app

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: devwebapp
  labels:
    app: devwebapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: devwebapp
  template:
    metadata:
      labels:
        app: devwebapp
    spec:
      serviceAccountName: internal-app
      containers:
      - name: app
        image: burtlo/devwebapp-ruby:k8s
        imagePullPolicy: Always
        env:
        - name: VAULT_ADDR
          value: "http://172.42.42.200:8200"


⇒  kubectl create -f yaml-files/03-deploy-devweb-app.yaml
serviceaccount/internal-app created
deployment.apps/devwebapp created


⇒  kubectl get pods
NAME                         READY   STATUS    RESTARTS   AGE
devwebapp-56c46857c4-wpxj6   1/1     Running   0          109s

```


## - Test and validate if external Vault URI is accesible from deployed POD
```
⇒  kubectl exec devwebapp-56c46857c4-wpxj6 -- curl -s http://external-vault:8200/v1/sys/seal-status | jq
{
  "type": "shamir",
  "initialized": true,
  "sealed": false,
  "t": 1,
  "n": 1,
  "progress": 0,
  "nonce": "",
  "version": "1.4.0+ent.hsm",
  "migration": false,
  "cluster_name": "vault-cluster-ddd38052",
  "cluster_id": "7e720e59-280e-55df-c4d1-134f940a32d8",
  "recovery_seal": true,
  "storage_type": "file"
}

```
## - Create a patch for the app deployed
- The patch has annotations which will instruct vault-injector to add sidecars to the deployment. 
- (Init side-car and vault-agent side-car)
```
⇒  cat 04-deploy-devweb-app-patch.yaml
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "devweb-app"
        vault.hashicorp.com/agent-inject-secret-credentials.txt: "secret/data/devwebapp/config"

-- Deploy the patch
⇒  kubectl patch deployment devwebapp --patch "$(cat yaml-files/04-deploy-devweb-app-patch.yaml)"
deployment.apps/devwebapp patched

⇒  kubectl get pods
NAME                                   READY   STATUS     RESTARTS   AGE
devwebapp-56c46857c4-wpxj6             1/1     Running    0          6m11s
devwebapp-75bd768987-tn98w             0/2     Init:0/1   0          21s
vault-agent-injector-9bcc59498-962vp   1/1     Running    0          2m27s

```

# -- Validate the patch deployed (both app & vault-agent side-car)
-- Check the pods, you should see a new pod initialized and deployed with patch. 
-- Check the READY status, you will see two container starting, Vault injector added vault-agent sidecar
```
-- Check the number of containers in devwebapp pod (2/2 READY)
⇒  kubectl get pods
NAME                                   READY   STATUS    RESTARTS   AGE
devwebapp-58c4895874-tgtr2             2/2     Running   0          5m53s
vault-agent-injector-9bcc59498-kvpvf   1/1     Running   0          27m

```


# - Let's check if the deployment pulled secrets from Vault
```
⇒  kubectl exec -it devwebapp-75bd768987-xrnk4 -c app -- cat /vault/secrets/credentials.txt
password: salsa
username: giraffe
```

# -- Troubleshooting & Checks
```
⇒  kubectl logs devwebapp-75bd768987-xrnk4 -c vault-agent-init -f
==> Vault server started! Log data will stream in below:

==> Vault agent configuration:

                     Cgo: disabled
               Log Level: info
                 Version: Vault v1.3.2

2020-06-19T08:10:54.478Z [INFO]  sink.file: creating file sink
2020-06-19T08:10:54.478Z [INFO]  sink.file: file sink configured: path=/home/vault/.token mode=-rw-r-----
2020-06-19T08:10:54.479Z [INFO]  template.server: starting template server
2020/06/19 08:10:54.479148 [INFO] (runner) creating new runner (dry: false, once: false)
2020/06/19 08:10:54.483911 [INFO] (runner) creating watcher
2020-06-19T08:10:54.484Z [INFO]  auth.handler: starting auth handler
2020-06-19T08:10:54.484Z [INFO]  auth.handler: authenticating
2020-06-19T08:10:54.485Z [INFO]  sink.server: starting sink server
2020-06-19T08:10:54.518Z [INFO]  auth.handler: authentication successful, sending token to sinks
2020-06-19T08:10:54.518Z [INFO]  auth.handler: starting renewal process
2020-06-19T08:10:54.543Z [INFO]  template.server: template server received new token
2020/06/19 08:10:54.552480 [INFO] (runner) stopping
2020/06/19 08:10:54.552518 [INFO] (runner) creating new runner (dry: false, once: false)
2020/06/19 08:10:54.552604 [INFO] (runner) creating watcher
2020/06/19 08:10:54.552655 [INFO] (runner) starting
2020-06-19T08:10:54.587Z [INFO]  sink.file: token written: path=/home/vault/.token
2020-06-19T08:10:54.587Z [INFO]  sink.server: sink server stopped
2020-06-19T08:10:54.587Z [INFO]  sinks finished, exiting
2020-06-19T08:10:54.591Z [INFO]  auth.handler: renewed auth token
2020/06/19 08:10:54.681223 [INFO] (runner) rendered "(dynamic)" => "/vault/secrets/credentials.txt"
2020/06/19 08:10:54.681247 [INFO] (runner) stopping
2020-06-19T08:10:54.681Z [INFO]  template.server: template server stopped
```




