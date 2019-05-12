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
-   path: /tmp/enroll_rhel_node.sh
    encoding: b64
    content: $(cat scripts/enroll_rhel_node.sh | base64 | tr -d '\n')
-   path: /etc/profile.env
    content: |
      export RH_USERNAME="${RH_USERNAME}"
      export RH_PASSWORD="${RH_PASSWORD}"
      export RH_POOL="${RH_POOL}"

users:
  - name: core
    groups: wheel
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - $(cat $HOME/.ssh/id_rsa.pub)

runcmd:
 - [ bash, /tmp/enroll_rhel_node.sh ]
 - [ reboot ]

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

