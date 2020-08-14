#!/bin/bash

set -e
echo "Setting environment variables .... \n"

timeout 180 /bin/bash -c \
  "while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do echo 'Waiting for apt to finish...'; sleep 1; done"

# set vault address for vault cli
tee -a /home/vagrant/.bash_profile <<EOF
export VAULT_ADDR=http://127.0.0.1:8200
EOF

tee -a /root/.bash_profile <<EOF
export VAULT_ADDR=http://127.0.0.1:8200
EOF

tee -a /home/vagrant/.bash_profile <<EOF
export GOPATH=/vagrant/go
export VAULTPATH=/opt/vault/bin
export PATH=\$PATH:\$GOPATH/bin:\$VAULTPATH
EOF

tee -a /root/.bash_profile <<EOF
export GOPATH=/vagrant/go
export VAULTPATH=/opt/vault/bin
export PATH=\$PATH:\$GOPATH/bin:\$VAULTPATH
EOF

echo "COMPLETED --> Setting environment varibles .... \n"
