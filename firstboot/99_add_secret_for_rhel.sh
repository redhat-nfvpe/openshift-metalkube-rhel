#!/bin/bash

source $HOME/settings.env

IGNITION_ENDPOINT="https://api.${CLUSTER_NAME}.${BASE_DOMAIN}:22623/config/worker"

cat > .cloudinit.tmp << EOF
write_files:
- path: /tmp/pull.json
  content: |
    $PULL_SECRET
- path: /root/.kube/config
  encoding: b64
  content: $(cat ocp/auth/kubeconfig | base64)
- path: /tmp/ignition_endpoint
  content: $IGNITION_ENDPOINT

users:
  - name: core
    groups: wheel
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - $(cat $HOME/.ssh/id_rsa.pub)

rh_subscription:
  username: $RH_USERNAME
  password: '$RH_PASSWORD'
  auto-attach: True
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

