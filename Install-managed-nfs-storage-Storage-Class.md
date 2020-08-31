# Install managed-nfs-storage Storage Class

## Hardware requirements

-  One computer which will be called **Installer** that runs Linux or MacOS.

## System requirements

- One  [OCP 4](https://github.com/bpshparis/sandbox/blob/master/Installing-Redhat-Openshift-4.4-on-Bare-Metal.md#installing-redhat-openshift-4.4-on-bare-metal)

- One **WEB server** where following files are available in **read mode**:
  - [nfs-client.zip](scripts/nfs-client.zip)

<br>

:checkered_flag::checkered_flag::checkered_flag:

<br>

## Install managed-nfs-storage Storage Class

>:information_source: Commands below are valid for a Linux/Centos 7.

>:warning: Some of commands below will need to be adapted to fit Linux/Debian or MacOS .

### Install NFS server

> :information_source: Run this on **NFS Server**

```
NFS_PATH="/exports"
```

```
cat > installNFSServer.sh << EOF
mkdir $NFS_PATH
echo "$NFS_PATH *(rw,sync,no_root_squash)" >> /etc/exports
[ ! -z $(rpm -qa nfs-utils) ] && echo nfs-utils installed || { echo nfs-utils not installed; yum install -y nfs-utils rpcbind; }
systemctl restart nfs
showmount -e
systemctl enable nfs
EOF
```

```
chmod +x installNFSServer.sh && ./installNFSServer.sh
```

### :bulb: Optional: Disable security

> :information_source: Run this on Installer

```
systemctl stop firewalld &&
systemctl disable firewalld &&
setenforce 0 &&
sed -i -e 's/^SELINUX=\w*/SELINUX=disabled/' /etc/selinux/config
```


### Test NFS server

#### Mount resource and test NFS server availability

> :information_source: Run this on **NFS Server**

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

> :information_source: Run this on **NFS Server**

```
[ -z $(command -v sshpass) ] && { yum install -y sshpass; export SSHPASS="spcspc"; }

sshpass -e ssh -o StrictHostKeyChecking=no $NFS_SERVER ls $NFS_PATH/ 
```

#### Clean things

> :information_source: Run this on **NFS Server**

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

#### Login to cluster

> :warning: Adapt settings to fit to your environment.

> :information_source: Run this on Installer

```
OC_URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.4.17/openshift-client-linux-4.4.17.tar.gz"
LB_HOSTNAME="cli-ocp5"
```

```
[ -z $(command -v oc) ] && { wget -c $OC_URL; tar -xvzf $(echo $OC_URL | awk -F'/' '{print $NF}') -C $(echo $PATH | awk -F":" 'NR==1 {print $1}'); oc version; } || { echo "oc and bubectl already installed"; }

oc login https://$LB_HOSTNAME:6443 -u admin -p admin --insecure-skip-tls-verify=true
```


#### Install and test storage class

> :information_source: Run this on Installer

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

> :information_source: Run this on Installer

```
sleep 5 && VOLUME=$(oc get pvc | awk '$1 ~ "test-claim" {print $3}') && echo $VOLUME

sshpass -e ssh -o StrictHostKeyChecking=no $NFS_SERVER ls /$NFS_PATH/$(oc project -q)-test-claim-$VOLUME && cd ~
```

<br>

:checkered_flag::checkered_flag::checkered_flag:

<br>


### Add persistent storage to the registry

#### Set default  storageclass

> :information_source: Run this on Installer

```
SC="managed-nfs-storage"

oc patch storageclass $SC -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

##### Remove emptyDir storage

> :information_source: Run this on Installer

```
oc patch configs.imageregistry.operator.openshift.io --type='json' -p='[{"op": "remove", "path": "/spec/storage/emptyDir"}]' --dry-run

oc patch configs.imageregistry.operator.openshift.io --type='json' -p='[{"op": "remove", "path": "/spec/storage/emptyDir"}]'
```

##### Add persistent storage to the registry

> :information_source: Run this on Installer

```
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"pvc":{"claim": ""}}}}'
```

<br>

:checkered_flag::checkered_flag::checkered_flag:
