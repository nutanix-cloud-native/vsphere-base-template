#!/bin/bash -eux

# exit if flatcar
if [[ $(grep -c Flatcar /etc/os-release) -gt 0 ]]; then
  # FIXME: this is a workaround for flat car support. We need to find a better way to do this.
  exit 0
fi

# ensure vmware datasource
echo 'datasource_list: [ "VMware", "OVF", "VMwareGuestInfo" ]' > /etc/cloud/cloud.cfg.d/99-ovf-data.cfg

echo "Cloud-Init version"
cloud-init --version


# remove default conf if given
rm -f /etc/cloud/cloud.cfg.d/99-installer.cfg

# clean cloud init
rm -Rf /var/lib/cloud/data/scripts \
       /var/lib/cloud/scripts/per-instance \
       /var/lib/cloud/data/user-data* \
       /var/lib/cloud/instance \
       /var/lib/cloud/instances/* \
       /etc/cloud/cloud-init.disabled

cloud-init clean --logs

# ensure cloud-init is enabled
# cloud-init 24.3+ renamed cloud-init.service -> cloud-init-network.service
# and added cloud-init-main.service as the primary single-process unit
if systemctl cat cloud-init-main.service >/dev/null 2>&1; then
  systemctl enable cloud-init-main.service cloud-init-network.service
else
  systemctl enable cloud-init
fi
