#!/bin/bash
set -eux
dhclient eth1 || true

# install packages
yum -y install epel-release

cat > /etc/yum.repos.d/cbs.centos.org_repos_paas7-crio-113-candidate_x86_64_os.repo <<EOL
[cbs.centos.org_repos_paas7-crio-113-candidate_x86_64_os]
name=added from: https://cbs.centos.org/repos/paas7-crio-113-candidate/x86_64/os
baseurl=https://cbs.centos.org/repos/paas7-crio-113-candidate/x86_64/os
enabled=1
gpgcheck=0
EOL

cat > /etc/yum.repos.d/rpms.svc.ci.openshift.org_openshift-origin-v4.0_.repo <<EOL
[rpms.svc.ci.openshift.org_openshift-origin-v4.0_]
name=added from: https://rpms.svc.ci.openshift.org/openshift-origin-v4.0/
baseurl=https://rpms.svc.ci.openshift.org/openshift-origin-v4.0/
enabled=1
gpgcheck=0
EOL

yum update -y

yum -y -t install git epel-release wget kernel irqbalance microcode_ctl systemd selinux-policy-targeted setools-console dracut-network passwd openssh-server openssh-clients podman skopeo runc containernetworking-plugins cri-tools nfs-utils NetworkManager dnsmasq lvm2 iscsi-initiator-utils sg3_utils device-mapper-multipath xfsprogs e2fsprogs mdadm cryptsetup chrony logrotate sssd shadow-utils sudo coreutils less tar xz gzip bzip2 rsync tmux nmap-ncat net-tools bind-utils strace bash-completion vim-minimal nano authconfig iptables-services biosdevname container-storage-setup cloud-utils-growpart glusterfs-fuse cri-o openshift-clients openshift-hyperkube

# enable cri-o
systemctl enable cri-o

# disable swap
swapoff -a

# enable ip forwarding
sysctl -w net.ipv4.ip_forward=1
sysctl --system

# set sebool container_manage_cgroup, disable selinux
setsebool -P container_manage_cgroup on || true
setenforce 0

# create temporary directory and extract contents there
TEMP_DIR=$(mktemp -d)
pushd $TEMP_DIR
IGNITION_URL=$(cat /tmp/ignition_endpoint )
curl -k $IGNITION_URL -o $TEMP_DIR/bootstrap.ign

# run release image
CLUSTER_VERSION=$(oc get clusterversion --config=/root/.kube/config --output=jsonpath='{.items[0].status.desired.image}')
podman pull --tls-verify=false --authfile /tmp/pull.json $CLUSTER_VERSION
RELEASE_IMAGE=$(podman run --rm $CLUSTER_VERSION image machine-config-daemon)

# run MCD image
podman pull --tls-verify=false --authfile /tmp/pull.json $RELEASE_IMAGE
podman run -v /:/rootfs -v /var/run/dbus:/var/run/dbus -v /run/systemd:/run/systemd --privileged --rm -ti $RELEASE_IMAGE start --node-name $HOSTNAME --once-from $TEMP_DIR/bootstrap.ign --skip-reboot

sed -i '/^.*linux16.*/ s/$/ ip=eth0:dhcp ip=eth1:dhcp rd.neednet=1/' /boot/grub2/grub.cfg
