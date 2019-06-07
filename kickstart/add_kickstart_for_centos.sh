#! /bin/bash

source $HOME/settings.env

IGNITION_ENDPOINT="https://api.${CLUSTER_NAME}.${BASE_DOMAIN}:22623/config/worker"
CORE_SSH_KEY=$(cat $HOME/.ssh/id_rsa.pub)
ENROLL_CENTOS_NODE=$(cat ../scripts/enroll_centos_node.sh)
KUBECONFIG_FILE=$(cat $KUBECONFIG_PATH)

cat > centos-worker-kickstart.cfg <<EOT
lang en_US
keyboard us
timezone Etc/UTC --isUtc
rootpw --plaintext ${ROOT_PASSWORD}
reboot
text
install
url --url=http://mirror.centos.org/centos/7.6.1810/os/x86_64/
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart
auth --passalgo=sha512 --useshadow
selinux --disabled
firewall --disabled
skipx
firstboot --disable
user --name=core --groups=wheel
%post --erroronfail --log=/root/ks-post.log

# Add core ssh key
mkdir -m0700 /home/core/.ssh
cat <<EOF > /home/core/.ssh/authorized_keys
${CORE_SSH_KEY}
EOF
chmod 0600 /home/core/.ssh/authorized_keys
chown -R core:core /home/core/.ssh
restorecon -R /home/core/.ssh

# enable passwordless sudo for wheel
echo "wheel   ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/wheel
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

# write pull secret
cat <<EOF > /tmp/pull.json
${PULL_SECRET}
EOF

# write kubeconfig
mkdir -p /root/.kube
cat <<EOF > /root/.kube/config
${KUBECONFIG_FILE}
EOF

# write ignition endpoint
cat <<EOF /tmp/ignition_endpoint
${IGNITION_ENDPOINT}
EOF

# write enroll script
cat <<EOF > /tmp/enroll_centos_node.sh
${ENROLL_CENTOS_NODE}
EOF

# execute enroll script
bash /tmp/enroll_node.sh
%end
%packages
@base
%end
EOT

