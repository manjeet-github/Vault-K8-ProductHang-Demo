#!/bin/bash

# Install Vault
echo "[TASK 3] Installing Hashicorp Vault ...............\n"

set -ex

VAULT_VERSION="1.5.0+ent.hsm"
VAULT_ZIP=vault_${VAULT_VERSION}_linux_amd64.zip
VAULT_URL=${URL:-https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_ZIP}}
VAULT_DIR="/opt/vault/bin"

apt-get update
apt-get install -y unzip
apt-get install -y libltdl7

sudo mkdir -p /etc/vault/
sudo mkdir -p /opt/vault/config
sudo mkdir -p /opt/vault/bin
sudo mkdir -p /opt/vault/filedata
sudo mkdir -p /var/lib/softhsm/tokens/
echo "Downloading Vault ${VAULT_VERSION}"
[ 200 -ne $(curl --write-out %{http_code} --silent --output /vagrant/${VAULT_ZIP} ${VAULT_URL}) ] && exit 1
sudo unzip -o /vagrant/${VAULT_ZIP} -d ${VAULT_DIR}
sudo cp /vagrant/vault.lic /opt/vault/bin/vault.lic
sudo chmod 0755 /opt/vault/bin/vault
sudo chown root:root /opt/vault/bin/vault

sudo /usr/sbin/groupadd --force --system vault

if ! getent passwd vault >/dev/null ; then
        sudo /usr/sbin/adduser \
          --system \
          --group \
          --no-create-home \
          --shell /bin/false \
          vault  >/dev/null
fi

echo "Installing Vault config file..."
tee /opt/vault/config/vault-hsm.hcl <<EOF
ui = true
disable_mlock = true
log_level = "Debug"

seal "pkcs11" {
  lib            = "/usr/lib/x86_64-linux-gnu/softhsm/libsofthsm2.so"
  slot           = "0"
  pin            = "1234"
  key_label      = "hsm_demo_key"
  hmac_key_label = "hsm_demo_hmac_key"
  generate_key   = "true"
}

storage "file" {
  path = "/opt/vault/filedata"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "true"
}

EOF

echo "Installing Vault startup script..."
sudo bash -c "cat >/etc/systemd/system/vault.service" << 'VAULTSVC'
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target

[Service]
User=root
Group=root
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/opt/vault/bin/vault server -config=/opt/vault/config/vault-hsm.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target

VAULTSVC
sudo chmod 0644 /etc/systemd/system/vault.service
sudo systemctl enable vault

echo "COMPLETED --> Installing Hashicorp Vault ........ \n"
