cdrom
# Use text mode install
text

# License agreement
eula --agreed

# System language
lang en_US.UTF-8

# Keyboard layout
keyboard --vckeymap=us --xlayouts='us'

# repo setup
url --url=http://dl.rockylinux.org/vault/rocky/${distribution_version}/BaseOS/x86_64/os/
repo --name=AppStream --baseurl=http://dl.rockylinux.org/vault/rocky/${distribution_version}/AppStream/x86_64/os/

# Network information
network --bootproto=dhcp --device=link --activate

### Lock the root account
rootpw --lock

firewall --disabled

# SELinux configuration
selinux --permissive

# Do not configure the X Window System
skipx

# System timezone
timezone UTC

# Add a user named builder
user --name=${ssh_username}
sshkey --username=${ssh_username} "${public_key}"

# System bootloader configuration
bootloader --location=mbr

# Clear the Master Boot Record
zerombr

clearpart --all --initlabel
part / --fstype="ext4" --grow --asprimary --label=slash --ondisk=sda

%packages --excludedocs
# dnf group info minimal-environment
@^minimal-environment
@core
openssh-server
sed
sudo
python3

# Exclude open-vm-tools from group install - it requires dbus-tools which is not
# on the minimal ISO. It will be installed in %post via dnf with full repo access.
-open-vm-tools

# Exclude unnecessary firmwares
-iwl*firmware
%end

# Enable/disable the following services
services --enabled=sshd

%post --logfile=/mnt/sysimage/root/ks-post.log --erroronfail
# Disable quiet boot and splash screen
sed --follow-symlinks -i "s/ rhgb quiet//" /etc/default/grub
sed --follow-symlinks -i "s/ rhgb quiet//" /boot/grub2/grubenv
# Passwordless sudo for the user '${ssh_username}'
echo "${ssh_username} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/${ssh_username}
chmod 440 /etc/sudoers.d/${ssh_username}

# Remove the package cache
dnf makecache
dnf install epel-release -y
dnf makecache
dnf install -y sudo open-vm-tools perl cloud-init cloud-utils-growpart
dnf -y upgrade open-vm-tools
dnf install -y openssh-server

# Disable swap
swapoff -a
rm -f /swapfile
sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab
sed -i '/^\(HWADDR\|UUID\)=/d' /etc/sysconfig/network-scripts/ifcfg-* || true
%end

# Reboot after successful installation
reboot
