#!/bin/bash

cat > /etc/yum.repos.d/redhat.repo <<EOF
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

yum update
