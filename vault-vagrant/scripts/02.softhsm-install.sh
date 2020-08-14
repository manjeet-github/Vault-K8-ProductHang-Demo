#!/bin/bash

set -e
echo "[TASK 2] Installing SoftHSM ..........\n"

sudo apt-get install -y software-properties-common
sudo apt-get update
sudo apt-get install -y softhsm2

sudo mkdir -p /var/lib/softhsm/tokens/

tee /etc/softhsm/softhsm2.conf <<EOF
# SoftHSM v2 configuration file
directories.tokendir = /var/lib/softhsm/tokens/
objectstore.backend = file

# ERROR, WARNING, INFO, DEBUG
log.level = DEBUG
EOF

echo "Initializing SoftHSM ..........\n"

sudo softhsm2-util \
--init-token         \
--slot 0             \
--label "hsm_demo"   \
--pin 1234           \
--so-pin asdf

echo "COMPLETED --> Installing SoftHSM ..........\n"
