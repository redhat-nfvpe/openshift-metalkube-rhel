#! /bin/bash

source $HOME/settings.env

IGNITION_ENDPOINT="https://api.${CLUSTER_NAME}.${BASE_DOMAIN}:22623/config/worker"
CORE_SSH_KEY=$(cat $HOME/.ssh/id_rsa.pub)
ENROLL_CENTOS_NODE=$(cat ./scripts/enroll_centos_node.sh)
KUBECONFIG_FILE=$(cat $KUBECONFIG_PATH)

cat > centos-worker-kickstart.cfg <<EOT
lang en_US
keyboard us
timezone Etc/UTC --isUtc
rootpw --plaintext ${ROOT_PASSWORD}
reboot
cmdline
install
url --url=http://mirror.centos.org/centos/7.6.1810/os/x86_64/
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart
auth --passalgo=sha512 --useshadow
selinux --disabled
services --enabled=iptables
skipx
firstboot --disable
user --name=core --groups=wheel
%post --nochroot --erroronfail --log=/mnt/sysimage/root/ks-post.log

# Add core ssh key
mkdir -m0700 /mnt/sysimage/home/core/.ssh
cat <<EOF > /mnt/sysimage/home/core/.ssh/authorized_keys
${CORE_SSH_KEY}
EOF
chmod 0600 /mnt/sysimage/home/core/.ssh/authorized_keys
chown -R core:core /mnt/sysimage/home/core/.ssh
restorecon -R /mnt/sysimage/home/core/.ssh

# enable passwordless sudo for wheel
echo "%wheel   ALL=(ALL)       NOPASSWD: ALL" >> /mnt/sysimage/etc/sudoers.d/wheel
sed -i "s/^.*requiretty/#Defaults requiretty/" /mnt/sysimage/etc/sudoers

# write pull secret
cat <<EOF > /mnt/sysimage/tmp/pull.json
${PULL_SECRET}
EOF

# write kubeconfig
mkdir -p /mnt/sysimage/root/.kube
cat <<EOF > /mnt/sysimage/root/.kube/config
${KUBECONFIG_FILE}
EOF

# write ignition endpoint
cat <<EOF > /mnt/sysimage/tmp/ignition_endpoint
${IGNITION_ENDPOINT}
EOF

# write enroll script
cat <<'EOF' > /mnt/sysimage/tmp/enroll_centos_node.sh
${ENROLL_CENTOS_NODE}
EOF

# execute enroll script
bash /mnt/sysimage/tmp/enroll_centos_node.sh
%end
%packages
@base
%end
EOT

