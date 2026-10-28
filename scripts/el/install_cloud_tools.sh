#!/bin/sh -eux

# run installing cloud tools again as an active subscription might be needed for install


# determine the major EL version we're runninng
major_version="$(sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release | awk -F. '{print $1}')";

# make sure we use dnf on EL 8+
if [ "$major_version" -ge 8 ]; then
    dnf -y install open-vm-tools cloud-init cloud-utils-growpart
    # Ensure we pick up the latest patched package version.
    dnf -y upgrade open-vm-tools
else
    # with el7 we install cloud-init from source
    yum install -y open-vm-tools cloud-init cloud-utils-growpart dracut-modules-growroot https://dl.fedoraproject.org/pub/archive/epel/7/x86_64/Packages/e/epel-release-7-14.noarch.rpm
    # Ensure we pick up the latest patched package version.
    yum -y update open-vm-tools
    yum install -y python2-pip python-netifaces python2-oauthlib python2-jsonschema
    pip install https://files.pythonhosted.org/packages/d3/bb/d10e531b297dd1d46f6b1fd11d018247af9f2d460037554bb7bb9011c6ac/configobj-5.0.8-py2.py3-none-any.whl
    yum install -y python36-pip
fi
