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

# temporary fix: downgrade and pin tuned
yum -y swap -- remove tuned -- install  tuned-2.9.0-1.el7fdp.noarch
yum -y install yum-versionlock
yum versionlock tuned

yum install -y kernel-rt rt-tests tuned-profiles-realtime
