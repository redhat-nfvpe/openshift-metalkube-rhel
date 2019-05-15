#!/bin/bash
cat <<EOF > /etc/yum.repos.d/CentOS-rt.repo
# CentOS-rt.repo

[rt]
name=CentOS-7 - rt
baseurl=http://mirror.centos.org/centos/\$releasever/rt/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF

yum update -y
yum install -y kernel-rt rt-tests tuned-profiles-realtime
