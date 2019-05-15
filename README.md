# openshift-metalkube-rhel
Automation to add a RHEL node to metalkube

This is based on [https://github.com/openshift/openshift-ansible](https://github.com/openshift/openshift-ansible) repo, but adapted to run in an standalone way.

## How to use it
This repo is providing a set of scripts to enable integration of RHEL/CentOS nodes on Metal3. The general idea behind it is to rely on a cloud-init script that will bring all the dependencies needed for a RHEL node to join an OpenShift cluster. This cloud-init script is embedded into a Kubernetes secret, that can be used inside a BaremetalHost CR definition on Metal3.
The scripts are relying on some env vars to be set, to generate a secret according to the cluster. The vars that need to be exported before running the script are:

 - CLUSTER_NAME: name of the deployed cluster
 - CLUSTER_DOMAIN: domain of the deployed cluster
 - PULL_SECRET: pull secret extracted from [https://access.redhat.com/management/products](https://cloud.openshift.com/clusters/install)
 - KUBECONFIG_PATH: points to a kubeconfig file that contains the authentication for the cluster

And for the case of RHEL, you also need to export the credentials needed for subscription:

 - RH_USERNAME: name for your RHEL subscription (typically email)
 - RH_PASSWORD: password for your RHEL subscription
 - RH_POOL: pool id that is going to be attached. It can be retrieved from [https://access.redhat.com/management/products](https://access.redhat.com/management/products)

The scripts are making use of a file **$HOME/settings.env** that will contain all those vars. So please create that file, including all the explained vars on it.
After the file is created with the right content, you can simply run any script:
    ./99_add_secret_for_rhel_rt.sh
This will generate a secret that will look like:

    apiVersion: v1
    data:
      userData: base64-encoded-content
    ind: Secret
    metadata:
      name: rhel-rt-worker-user-data
      namespace: openshift-machine-api
    type: Opaque

Once this secret is on place, it can be applied with the traditional kubectl apply (be sure to apply to the openshift-machine-api namespace)
In order to be integrated into a Metal3 BaremetalHost, it needs to be included on the host definition:

    ---
    apiVersion: v1
    kind: Secret
    metadata:
      name: rhel-secret
    type: Opaque
    data:
      username: base64_encoded_user
      password: base64_encoded_pass
    ---
    apiVersion: metalkube.org/v1alpha1
    kind: BareMetalHost
    metadata:
      name: rhel-host
    spec:
      online: true
      bmc:
        address: ipmi://xx.xx.xx.xx
        credentialsName: rhel-secret
      bootMACAddress: xx:xx:xx:xx:xx:xx
      image:
        checksum: http://172.22.0.1/images/rhel-guest.qcow2.md5sum
        url: http://172.22.0.1/images/rhel-guest.qcow2
      userData:
        namespace: openshift-machine-api
        name: rhel-rt-worker-user-data

Once this is applied, a new baremetal host will be provisioned and it will inject the rhel-rt-worker-user-data secret in a config-drive, to be used by cloud-init. This contains all dependencies for a node to join an existing kubernetes cluster.

