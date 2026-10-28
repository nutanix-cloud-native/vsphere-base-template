#!/bin/sh -eux

# Thanks to github.com/chef/bento
# taken from https://github.com/chef/bento/blob/0c64148b2179bdb88268b06425cdde657f9169f0/packer_templates/scripts/_common/vmware_rhel.sh

# determine the major EL version we're runninng
major_version="$(sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release | awk -F. '{print $1}')";

# make sure we use dnf on EL 8+
if [ "$major_version" -ge 8 ]; then
    dnf -y install open-vm-tools
    # Ensure we pick up the latest patched package version.
    dnf -y upgrade open-vm-tools
else
    yum -y install open-vm-tools
    # Ensure we pick up the latest patched package version.
    yum -y update open-vm-tools
fi

