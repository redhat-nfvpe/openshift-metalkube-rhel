#!/bin/bash

source $HOME/settings.env

IGNITION_ENDPOINT="https://api.${CLUSTER_NAME}.${BASE_DOMAIN}:22623/config/worker"

cat > .cloudinit.tmp << EOF
#cloud-config
write_files:
-   path: /tmp/pull.json
    content: $(echo $PULL_SECRET | base64 | tr -d '\n')
    encoding: b64
-   path: /root/.kube/config
    encoding: b64
    content: $(cat ocp/auth/kubeconfig | base64 | tr -d '\n')
-   path: /tmp/ignition_endpoint
    content: $IGNITION_ENDPOINT
-   path: /tmp/cloud_init_script.sh
    content: |
        #!/bin/bash
        set -eux
        dhclient eth1
        subscription-manager register --username $RH_USERNAME --password $RH_PASSWORD --force
        subscription-manager attach --pool=$RH_POOL
        subscription-manager repos --enable=rhel-7-server-rpms
        subscription-manager repos --enable=rhel-7-server-extras-rpms
        subscription-manager repos --enable=rhel-7-server-rh-common-rpms
        subscription-manager repos --enable=rhel-7-server-rt-rpms
        yum update -y
        yum -y -t install git epel-release python-setuptools wget
        yum -y groupinstall RT
        pushd /tmp
        wget https://bootstrap.pypa.io/get-pip.py
        python get-pip.py
        pip install ansible
        rm -rf openshift-metalkube-rhel
        git clone https://github.com/yrobla/openshift-metalkube-rhel
        pushd openshift-metalkube-rhel/ansible
        ansible-playbook play.yml -i localhost,
        sed -i '/^.*linux16.*/ s/$/ ip=eth0:dhcp ip=eth1:dhcp rd.neednet=1/' /boot/grub2/grub.cfg
        reboot

users:
  - name: core
    groups: wheel
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - $(cat $HOME/.ssh/id_rsa.pub)

runcmd:
 - [ bash, /tmp/cloud_init_script.sh ]

EOF

cat > rhel-worker-user-data.yaml << EOF
apiVersion: v1
data:
  userData: $(base64 -w 0 .cloudinit.tmp)
kind: Secret
metadata:
  name: rhel-worker-user-data
  namespace: openshift-machine-api
type: Opaque
EOF

