# Prepare Redhat Openshift for Cloud Paks

## Hardware requirements

-  One computer which will be called **Installer** that runs Linux or MacOS, with 500 MB of local disk space.

## System requirements

<!--
- One [OCP 3.11](https://github.com/bpshparis/sandbox/blob/master/Installing-Redhat-Openshift-3.11-on-Bare-Metal.md#installing-redhat-openshift-311-on-bare-metal) or [OCP 4](https://github.com/bpshparis/sandbox/blob/master/Installing-Redhat-Openshift-4-on-Bare-Metal.md#installing-redhat-openshift-4-on-bare-metal)
- One [centos/redhat Cli](https://github.com/bpshparis/sandbox/blob/master/Installing-Redhat-Openshift-4.3-on-Bare-Metal.md#create-cli) with **oc** and **kubectl** commands installed
- One **WEB server** where following files are available in **read mode**:
  - [nfs-client.zip](scripts/nfs-client.zip)
-->

- One  [OCP 4](https://github.com/bpshparis/sandbox/blob/master/Installing-Redhat-Openshift-4-on-Bare-Metal.md#installing-redhat-openshift-4-on-bare-metal)

- One **WEB server** where following files are available in **read mode**:
  - [Linux](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz) or [MacOS](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-mac.tar.gz) Openshift command line interface
  - Portworx Enterprise Edition (Part number **CC648EN**) downloaded either from [IBM Passport Advantage](https://www.ibm.com/software/passportadvantage/pao_customer.html) or from [XL](https://w3-03.ibm.com/software/xl/download/ticket.wss).


:checkered_flag::checkered_flag::checkered_flag:

<!--
## Install managed-nfs-storage Storage Class

### Install NFS server

> :information_source: Run this on Cli or any **centos/redhat linux device**

```
NFS_PATH="/exports"
```

```
cat > installNFSServer.sh << EOF
mkdir /exports
echo "$NFS_PATH *(rw,sync,no_root_squash)" >> /etc/exports
[ ! -z $(rpm -qa nfs-utils) ] && echo nfs-utils installed || { echo nfs-utils not installed; yum install -y nfs-utils rpcbind; }
systemctl restart nfs
showmount -e
systemctl enable nfs
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i -e 's/^SELINUX=\w*/SELINUX=disabled/' /etc/selinux/config
EOF
```

```
chmod +x installNFSServer.sh && ./installNFSServer.sh
```

### Test NFS server

#### Mount resource and test NFS server availability

> :information_source: Run this on Cli or any **centos/redhat linux device**

```
NFS_SERVER="cli-ocp5"
NFS_PATH="/exports"
```

```
[ ! -z $(rpm -qa nfs-utils) ] && echo nfs-utils installed || { echo nfs-utils not installed; yum install -y nfs-utils rpcbind; }

[ ! -d "/mnt/$NFS_SERVER" ] && mkdir /mnt/$NFS_SERVER && mount -t nfs $NFS_SERVER:$NFS_PATH /mnt/$NFS_SERVER

touch /mnt/$NFS_SERVER/SUCCESS && echo "RC="$?
```

> :warning: Next commands shoud display **SUCCESS**

> :information_source: Run this on Cli or any **centos/redhat linux device**

```
[ -z $(command -v sshpass) ] && { yum install -y sshpass; export SSHPASS="spcspc"; }

sshpass -e ssh -o StrictHostKeyChecking=no $NFS_SERVER ls $NFS_PATH/ 
```

#### Clean things

> :information_source: Run this on Cli or any **centos/redhat linux device**

```
NFS_SERVER="cli-ocp5"
NFS_PATH="/exports"
```

```
rm -f /mnt/$NFS_SERVER/SUCCESS && echo "RC="$?

sshpass -e ssh -o StrictHostKeyChecking=no $NFS_SERVER ls $NFS_PATH/

umount /mnt/$NFS_SERVER && rmdir /mnt/$NFS_SERVER && echo "RC="$?
```


### Install managed-nfs-storage Storage Class 

#### Log in OCP

> :information_source: Run this on **OCP 3.11** Cli

```
oc login https://cli-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true
```

> :information_source: Run this on **OCP 4.3** Cli

```
oc login https://cli-$OCP:6443 -u admin -p admin --insecure-skip-tls-verify=true
```


#### Install and test storage class

> :information_source: Run this on Cli

```
WEB_SERVER_SOFT_URL="http://web/soft"
NFS_SERVER="cli-ocp5"
NFS_PATH="/exports"
```

```
cd ~ 
wget -c $WEB_SERVER_SOFT_URL/nfs-client.zip
[ -z $(command -v unzip) ] && { yum install unzip -y; } || echo "unzip already installed"
unzip nfs-client.zip
cd nfs-client/

oc new-project storage

sed -i -e 's/namespace:.*/namespace: '$(oc project -q)'/g' ./deploy/rbac.yaml
oc create -f deploy/rbac.yaml
oc adm policy add-scc-to-user hostmount-anyuid system:serviceaccount:$(oc project -q):nfs-client-provisioner

sed -i -e 's/<NFS_SERVER>/'$NFS_SERVER'/g' deploy/deployment.yaml
sed -i -e 's:<NFS_PATH>:'$NFS_PATH':g' deploy/deployment.yaml

oc create -f deploy/class.yaml
oc create -f deploy/deployment.yaml

sleep 10

oc get pods
oc logs $(oc get pods | awk 'NR>1 {print $1}')
oc create -f deploy/test-claim.yaml
oc create -f deploy/test-pod.yaml
```

> :warning: Wait for test-pod to be deployed and check that next commands display **SUCCESS**

> :information_source: Run this on Cli

```
sleep 5 && VOLUME=$(oc get pvc | awk '$1 ~ "test-claim" {print $3}') && echo $VOLUME

sshpass -e ssh -o StrictHostKeyChecking=no $NFS_SERVER ls /$NFS_PATH/$(oc project -q)-test-claim-$VOLUME && cd ~
```

:checkered_flag::checkered_flag::checkered_flag:
-->


## Exposing Openshift Registry

> :bulb: Target is to be able to push docker images Openshift registry in a secure way.

> :information_source: Commands below are valid for a **Linux/Centos 7**.

> :warning: Some of commands below will need to be adapted to fit Linux/Debian or MacOS .

### Install oc and kubectl commands

> :warning: Adapt settings to fit to your environment.

> :information_source: Run this on Installer

```
WEB_SERVER_OC_URL="http://web/soft/openshift-client-linux-4.3.1.tar.gz"
OC_FILE="openshift-client-linux-4.3.1.tar.gz"
```

```
[ -z $(command -v oc) ] && { wget -c $WEB_SERVER_OC_URL; tar xvzf $OC_FILE -C $(echo $PATH | awk -F':' '{print $1}'); } || echo oc installed
```

### Install podman

> :information_source: Run this on Installer

```
[ -z $(command -v podman) ] && { yum install podman crictl runc buildah skopeo -y; } || echo "podman already installed"
```

### Log in cluster default project

<!--
> :information_source: Run this on **OCP 3.11** Cli

```
oc login https://cli-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true -n default
```
> :arrow_heading_down: [Exposing Openshift 3 Registry](#exposing-openshift-3-registry)

<br>

> :information_source: Run this on **OCP 4.3** Cli
-->

> :warning: Adapt settings to fit to your environment.

> :information_source: Run this on Installer

```
LB_HOSTNAME="cli-ocp7"
```

```
oc login https://$LB_HOSTNAME:6443 -u admin -p admin --insecure-skip-tls-verify=true -n default
```

<!--
> :arrow_heading_down: [Exposing Openshift 4 Registry](#exposing-openshift-4-registry)

<br>

### Exposing Openshift 3 Registry

> :information_source: Run this on **OCP 3.11** Cli

```
[ -z $(command -v jq) ] && { wget -c https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && chmod +x jq-linux64 && mv jq-linux64 /usr/local/sbin/jq; } || echo jq already installed
```

#### Check Openshift 3 registry route

> :warning: Termination should display **passthrough** if not proceed as describe [here](https://docs.openshift.com/container-platform/3.11/install_config/registry/securing_and_exposing_registry.html#exposing-the-registry)

> :information_source: Run this on **OCP 3.11** Cli

```
oc get route/docker-registry -n default -o json | jq -r .spec.tls.termination
```

#### Trust Openshift 3 registry

> :information_source: Run this on **OCP 3.11** Cli

```
REG_HOST=$(oc get route/docker-registry -n default -o json | jq -r .spec.host) && echo $REG_HOST

mkdir -p /etc/docker/certs.d/$REG_HOST

sshpass -e scp -o StrictHostKeyChecking=no m1-$OCP:/etc/origin/master/ca.crt /etc/docker/certs.d/$REG_HOST
```

> :arrow_heading_down: [Log in Openshift registry](#log-in-openshift-registry)

<br>
-->

### Exposing Openshift Registry

> :information_source: Run this on Installer

```
oc patch configs.imageregistry.operator.openshift.io/cluster --type merge -p '{"spec":{"defaultRoute":true}}'
```

#### Trust Openshift registry

> :information_source: Run this on Installer

```
REG_HOST=$(oc registry info) && echo $REG_HOST

mkdir -p /etc/containers/certs.d/$REG_HOST

oc extract secret/router-ca --keys=tls.crt -n openshift-ingress-operator

cp -v tls.crt /etc/containers/certs.d/$REG_HOST/
```

<br>

### Log in Openshift registry

> :information_source: Run this on Installer

```
podman login -u $(oc whoami) -p $(oc whoami -t) $REG_HOST
```

### Tag an image with Openshift registry hostname and push it

> :information_source: Run this on Installer

```
podman pull busybox
podman tag docker.io/busybox $REG_HOST/$(oc project -q)/busybox
```

> :warning: Now you have to be able to push images to Openshift registry

> :information_source: Run this on Installer

```
podman push $REG_HOST/$(oc project -q)/busybox
```

<br>

:checkered_flag::checkered_flag::checkered_flag:

<br>


<!-- 

podman pull busybox

podman login default-route-openshift-image-registry.apps.$OCP.iicparis.fr.ibm.com -u $(oc whoami) -p $(oc whoami -t) --tls-verify=false

podman push default-route-openshift-image-registry.apps.$OCP.iicparis.fr.ibm.com/validate/busybox --tls-verify=false

-->