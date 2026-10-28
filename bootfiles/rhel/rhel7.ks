# Perform a fresh install, not an upgrade
install
cdrom
# Perform a text installation
text



# Do not install an X server
skipx
# Configure the locale/keyboard
lang en_US.UTF-8
keyboard us
# Configure networking
network --onboot yes --bootproto dhcp --hostname el7
firewall --disabled
selinux --permissive
timezone UTC
# Don't flip out if unsupported hardware is detected
unsupported_hardware
# Configure the user(s)
auth --enableshadow --passalgo=sha512 --kickstart
user --name=${ssh_username} --groups=${ssh_username},wheel
sshkey --username=${ssh_username} "${public_key}"
# Disable general install minutia
firstboot --disabled
eula --agreed
# Create a single partition with no swap space
bootloader --location=mbr
zerombr

clearpart --all --initlabel
part / --grow --asprimary --fstype=ext4 --label=slash
%packages --excludedocs
openssh-server
sed
sudo
# Remove unnecessary firmware
-*-firmware
# Remove other unnecessary packages
-postfix
%end
# Enable/disable the following services
services --enabled=sshd
# Perform a reboot once the installation has completed
reboot

# The %post section is essentially a shell script
%post --erroronfail
# Update the root certificates
update-ca-trust force-enable
# Passwordless sudo for the user '${ssh_username}'
echo '${ssh_username} ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/${ssh_username}
chmod 440 /etc/sudoers.d/${ssh_username}
# Install image tools
yum install -y open-vm-tools cloud-utils-growpart dracut-modules-growroot
yum -y update open-vm-tools

# Remove the package cache
yum -y clean all
# Disable swap
swapoff -a
rm -f /swapfile
sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab
# Ensure on next boot that network devices get assigned unique IDs.
sed -i '/^\(HWADDR\|UUID\)=/d' /etc/sysconfig/network-scripts/ifcfg-*
%end
