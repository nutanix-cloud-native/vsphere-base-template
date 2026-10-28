#!/bin/sh -eux

dnf -y install open-vm-tools cloud-utils-growpart
# Ensure we pick up the latest patched package version.
dnf -y upgrade open-vm-tools
