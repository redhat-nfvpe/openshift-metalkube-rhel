#!/bin/bash

source $HOME/settings.env

IGNITION_ENDPOINT="https://api.${CLUSTER_NAME}.${BASE_DOMAIN}:22623/config/worker"

cat > .cloudinit.tmp << EOF
#cloud-config
write_files:
-   path: /tmp/pull.json
    content: $PULL_SECRET
-   path: /root/.kube/config
    encoding: b64
    content: $(cat ocp/auth/kubeconfig | base64 | tr -d '\n')
-   path: /tmp/ignition_endpoint
    content: $IGNITION_ENDPOINT
-   path: /tmp/cloud_init_script.sh
    content: |
        #!/bin/bash
        subscription-manager register --username $RH_USERNAME --password $RH_PASSWORD
        subscription-manager attach --pool=$RH_POOL
        subscription-manager repos --enable=rhel-7-server-rpms
        subscription-manager repos --enable=rhel-7-server-extras-rpms
        subscription-manager repos --enable=rhel-7-server-rh-common-rpms
        yum update -y
        yum -y -t install git epel-release python-setuptools wget
        pushd /tmp
        wget https://bootstrap.pypa.io/get-pip.py
        python get-pip.py
        pip install ansible
        git clone https://github.com/yrobla/openshift-metalkube-rhel
        pushd openshift-metalkube-rhel/ansible
        ansible-playbook play.yml -i localhost,
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

