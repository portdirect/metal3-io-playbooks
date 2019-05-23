#!/usr/bin/env bash

sudo yum update -y
sudo yum install -y libselinux-utils
if selinuxenabled ; then
    sudo setenforce permissive
    sudo sed -i "s/=enforcing/=permissive/g" /etc/selinux/config
fi

# Install EPEL required by some packages
if [ ! -f /etc/yum.repos.d/epel.repo ] ; then
    if grep -q "Red Hat Enterprise Linux" /etc/redhat-release ; then
        sudo yum -y install http://mirror.centos.org/centos/7/extras/x86_64/Packages/epel-release-7-11.noarch.rpm
    else
        sudo yum -y install epel-release --enablerepo=extras
    fi
fi

# Update to latest packages first
sudo yum -y update
sudo yum -y install \
  curl \
  python-virtualenv \
  python-devel \
  redhat-rpm-config \
  gcc


if [[ "$(python -c 'import sys; print(sys.version_info[0])')" == "2" ]]; then
    TMP_VIRTUALENV="virtualenv"
else
    TMP_VIRTUALENV="python3 -m virtualenv --python=python3"
fi

# This little dance allows us to install the latest pip and setuptools
# without get_pip.py or the python-pip package (in epel on centos)
if (( $(${TMP_VIRTUALENV} --version | cut -d. -f1) >= 14 )); then
    SETUPTOOLS="--no-setuptools"
fi

# virtualenv 16.4.0 fixed symlink handling. The interaction of the new
# corrected behavior with legacy bugs in packaged virtualenv releases in
# distributions means we need to hold on to the pip bootstrap installation
# chain to preserve symlinks. As distributions upgrade their default
# installations we may not need this workaround in the future
PIPBOOTSTRAP=/var/lib/pipbootstrap

# Create the boostrap environment so we can get pip from virtualenv
sudo ${TMP_VIRTUALENV} --extra-search-dir=/tmp/wheels ${SETUPTOOLS} ${PIPBOOTSTRAP}
source ${PIPBOOTSTRAP}/bin/activate

# Upgrade to the latest version of virtualenv
sudo sh -c "source ${PIPBOOTSTRAP}/bin/activate; pip install --upgrade ${PIP_ARGS} virtualenv"

# Forget the cached locations of python binaries
hash -r

# Create the virtualenv with the updated toolchain for openstack service
sudo mkdir -p /var/lib/openstack
sudo chown "$(whoami)" /var/lib/openstack
virtualenv /var/lib/openstack

# Deactivate the old bootstrap virtualenv and switch to the new one
deactivate
source /var/lib/openstack/bin/activate

# Install python packages not included as rpms
pip install --upgrade ${PIP_ARGS} ansible ara

deactivate
echo "export PATH=/var/lib/openstack/bin:\${PATH}" >> ${HOME}/.bash_profile
source ${HOME}/.bash_profile
sudo sh -c "echo PATH=/var/lib/openstack/bin:\$PATH >> /etc/environment"
