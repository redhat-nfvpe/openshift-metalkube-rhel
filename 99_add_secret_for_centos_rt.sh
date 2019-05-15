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
    content: $(cat $KUBECONFIG_PATH | base64 | tr -d '\n')
-   path: /tmp/ignition_endpoint
    content: $IGNITION_ENDPOINT
-   path: /tmp/enroll_centos_node.sh
    encoding: b64
    content: $(cat scripts/enroll_centos_node.sh | base64 | tr -d '\n')
-   path: /tmp/add_centos_rt_kernel.sh
    encoding: b64
    content: $(cat scripts/add_centos_rt_kernel.sh | base64 | tr -d '\n')

users:
  - name: core
    groups: wheel
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - $(cat $HOME/.ssh/id_rsa.pub)

runcmd:
 - [ 'bash', '/tmp/enroll_centos_node.sh' ]
 - [ 'bash', '/tmp/add_centos_rt_kernel.sh' ]

power_state:
    mode: reboot
EOF

cat > centos-rt-worker-user-data.yaml << EOF
apiVersion: v1
data:
  userData: $(base64 -w 0 .cloudinit.tmp)
kind: Secret
metadata:
  name: centos-rt-worker-user-data
  namespace: openshift-machine-api
type: Opaque
EOF
