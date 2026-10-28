#!/bin/sh -eux

echo "installing open-vm-tools"
apt-get update
apt-get install -y open-vm-tools
# Ensure we pick up the latest patched package version.
apt-get install -y --only-upgrade open-vm-tools
mkdir /mnt/hgfs
systemctl enable open-vm-tools
systemctl start open-vm-tools
