#!/bin/bash

cat > /etc/yum.repos.d/rhel.repo <<EOF
[rhel-8-for-x86_64-baseos-beta-rpms]
name = Red Hat Enterprise Linux 8 for x86_64 - BaseOS Beta (RPMs)
baseurl = https://downloads.redhat.com/redhat/rhel/rhel-8-beta/baseos/x86_64/
enabled = 1
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-beta,file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

[rhel-8-for-x86_64-appstream-beta-rpms]
name = Red Hat Enterprise Linux 8 for x86_64 - AppStream Beta (RPMs)
baseurl = https://downloads.redhat.com/redhat/rhel/rhel-8-beta/appstream/x86_64/
enabled = 1
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-beta,file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
EOF

dnf -y update
dnf install python3 --allowerasing -y
dnf install -y git

pip3 install ansible
ln -sf /usr/bin/python3 /usr/bin/python

pushd tmp
git clone https://github.com/yrobla/openshift-metalkube-rhel
pushd openshift-metalkube-rhel/ansible

ansible-playbook play.yml -i localhost,
