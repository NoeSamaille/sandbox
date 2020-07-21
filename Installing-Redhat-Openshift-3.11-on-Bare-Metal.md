# Installing Redhat Openshift 3.11 on Bare Metal


## Redhat requirements

Be a [Redhat partner](https://partnercenter.redhat.com/Dashboard_page) and ask for [NEW NFR](https://partnercenter.redhat.com/NFR_Redirect) to get access to Redhat Openshift packages.

:warning: NFR request could take several days to be validate.


## Hardware requirements

One Lenovo **X3550M5** or similar to host **4** virtual machines:

| name                        | role                  | vcpus  | ram (GB) | storage (GB) | ethernet (10GB) |
| --------------------------- | --------------------- | ------ | -------- | ------------ | --------------- |
| m1-ocp1.iicparis.fr.ibm.com | master + infra + etcd | 8      | 16       | 250          | 1               |
| w1-ocp1.iicparis.fr.ibm.com | worker                | 16     | 64       | 250          | 1               |
| w2-ocp1.iicparis.fr.ibm.com | worker                | 16     | 64       | 250          | 1               |
| w3-ocp1.iicparis.fr.ibm.com | worker                | 16     | 64       | 250          | 1               |
| **TOTAL**                   |                       | **56** | **196**  | **1000**     | **4**           |


## System requirements

- One **VMware vSphere Hypervisor** [5.5](https://my.vmware.com/en/web/vmware/evalcenter?p=free-esxi5), [6.7](https://my.vmware.com/en/web/vmware/evalcenter?p=free-esxi6) or [7.0](https://my.vmware.com/en/web/vmware/evalcenter?p=free-esxi7) with **ESXi Shell access enabled**. VCenter is NOT required.

- Two **vmdk (rhel.vmdk and rhel-flat.vmdk)** file which host  a [minimal](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/chap-simple-install#sect-simple-install) and  [prepared](https://docs.openshift.com/container-platform/3.11/install/host_preparation.html) RHEL7 **booting in dhcp**, **running VMware Tools** with **localhost.localdomain** as hostname. 

- One **DNS server**.

- One **DHCP server**.

- One **WEB server** where following files are available in **read mode**:

  - rhel.vmdk
  - rhel-flat.vmdk
  - [rhel.vmx](scripts/rhel.vmx)
  - [createOCP3Cluster.sh](scripts/createOCP3Cluster.sh)
  - [setHostAndIP.sh](scripts/setHostAndIP.sh)
  - [extendRootLV.sh](scripts/extendRootLV.sh)
  - [getVMAddress.sh](scripts/getVMAddress.sh)
  - [hosts-cluster](scripts/hosts-cluster)


:checkered_flag::checkered_flag::checkered_flag:

## Add DNS records

> :information_source: Run this on DNS

```
export DOMAIN="iicparis.fr.ibm.com"
export IP_HEAD="172.16"
export OCP=ocp1
export M1_IP=$IP_HEAD.187.11
export W1_IP=$IP_HEAD.187.14
export W2_IP=$IP_HEAD.187.15
export W3_IP=$IP_HEAD.187.16
```
### Add records to master zone

> :information_source: Run this on DNS

```
cat >> /var/lib/bind/$DOMAIN.hosts << EOF
m1-$OCP.$DOMAIN.   IN      A       $M1_IP
w1-$OCP.$DOMAIN.   IN      A       $W1_IP
w2-$OCP.$DOMAIN.   IN      A       $W2_IP
w3-$OCP.$DOMAIN.   IN      A       $W3_IP
apps.$OCP.$DOMAIN. IN      A       $M1_IP
*.apps.$OCP.$DOMAIN.       IN      CNAME   apps.$OCP.$DOMAIN.
EOF
```

### Add records to reverse zone

> :information_source: Run this on DNS

```
cat >> /var/lib/bind/$IP_HEAD.rev << EOF
$(echo $M1_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     m1-$OCP.$DOMAIN.
$(echo $W1_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     w1-$OCP.$DOMAIN.
$(echo $W2_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     w2-$OCP.$DOMAIN.
$(echo $W3_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     w3-$OCP.$DOMAIN.
EOF
```

### Restart DNS service

> :information_source: Run this on DNS

```
service bind9 restart 
```

### Test master zone

> :information_source: Run this on DNS

```
for host in m1 w1 w2 w3; do echo -n $host-$OCP "-> "; dig @localhost +short $host-$OCP.$DOMAIN; done
```

### Test reverse zone

> :information_source: Run this on DNS

```
for host in m1 w1 w2 w3; do IP=$(dig @localhost +short $host-$OCP.$DOMAIN); echo -n $IP " -> "; dig @localhost +short -x $IP; done
```

### Test alias

> :information_source: Run this on DNS

```
dig @localhost +short *.apps.$OCP.iicparis.fr.ibm.com
```
:checkered_flag::checkered_flag::checkered_flag:

## Create Cluster

### Download necessary stuff

> :information_source: Run this on ESX

```
WEB_SERVER_URL="http://web"

wget -c $WEB_SERVER_URL/rhel-flat.vmdk
wget -c $WEB_SERVER_URL/rhel.vmdk
wget -c $WEB_SERVER_URL/rhel.vmx
wget -c $WEB_SERVER_URL/createOCP3Cluster.sh
chmod +x createOCP3Cluster.sh
```

### Create cluster nodes

>:warning: Set **OCP**, **DATASTORE**, **VMS_PATH**, **VMDK** and **VMX** variables accordingly in **createOCP3Cluster.sh** before proceeding.

> :information_source: Run this on ESX

```
./createOCP3Cluster.sh masters
./createOCP3Cluster.sh workers
```

### Start cluster nodes

> :information_source: Run this on ESX

```
vim-cmd vmsvc/getallvms | awk '$2 ~ "[wm][1-5]|lb|cli|nfs|ctl" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh
vim-cmd vmsvc/getallvms | awk '$2 ~ "[wm][1-5]|lb|cli|nfs|ctl" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh
```

### Get cluster nodes dhcp ip address

> :warning: **getVMAddress.sh** will need to be adapted if network is different from **172.16.160.0/19**

> :warning: Wait for cluster nodes to be up and display its dhcp address in the **3rd column**

> :information_source: Run this on ESX

```
VM_DYN_ADDR="dyn-addresses"
wget -c $WEB_SERVER_URL/getVMAddress.sh
chmod +x getVMAddress.sh
watch -n 5 "./getVMAddress.sh | tee $VM_DYN_ADDR"
```

> :bulb: Leave watch with **Ctrl + c**


### Configure cluster nodes

#### Download necessary stuff

> :information_source: Run this on ESX

```
WEB_SERVER_URL="http://web"

wget -c $WEB_SERVER_URL/setHostAndIP.sh 
chmod +x setHostAndIP.sh
wget -c $WEB_SERVER_URL/extendRootLV.sh
chmod +x extendRootLV.sh
```

#### Create and copy ESXi public key to cluster nodes

> :warning: To be able to ssh from ESXi you need to enable sshClient rule outgoing port

> :information_source: Run this on ESXi

```
esxcli network firewall ruleset set -e true -r sshClient
```

> :information_source: Run this on ESXi

```
[ ! -d "/.ssh" ] && mkdir /.ssh 
/usr/lib/vmware/openssh/bin/ssh-keygen -t rsa -b 4096 -N "" -f /.ssh/id_rsa

for ip in $(awk -F ";" '{print $3}' $VM_DYN_ADDR); do cat /.ssh/id_rsa.pub | ssh -o StrictHostKeyChecking=no root@$ip '[ ! -d "/root/.ssh" ] && mkdir /root/.ssh && cat >> /root/.ssh/authorized_keys'; done
```

#### Extend cluster nodes Root logical volume

>:warning: Set **DISK**, **PART**, **VG** and **LV** variables accordingly in **extendRootLV.sh** before proceeding.

> :information_source: Run this on ESX

```
for ip in $(awk -F ";" '{print $3}' $VM_DYN_ADDR); do echo "copying extendRootLV.sh to" $ip "..."; scp -o StrictHostKeyChecking=no extendRootLV.sh root@$ip:/root; done

for ip in $(awk -F ";" '{print $3}' $VM_DYN_ADDR); do ssh -o StrictHostKeyChecking=no root@$ip 'hostname -f; /root/extendRootLV.sh'; done

for ip in $(awk -F ";" '{print $3}' $VM_DYN_ADDR); do ssh -o StrictHostKeyChecking=no root@$ip 'hostname -f; lvs'; done
```

#### Set cluster nodes static ip address and reboot

> :information_source: Run this on ESX

```
for ip in $(awk -F ";" '{print $3}' $VM_DYN_ADDR); do echo "copy to" $ip; scp -o StrictHostKeyChecking=no setHostAndIP.sh root@$ip:/root; done

for LINE in $(awk -F ";" '{print $0}' $VM_DYN_ADDR); do  HOSTNAME=$(echo $LINE | cut -d ";" -f2); IPADDR=$(echo $LINE | cut -d ";" -f3); echo $HOSTNAME; echo $IPADDR; ssh -o StrictHostKeyChecking=no root@$IPADDR '/root/setHostAndIP.sh '$HOSTNAME; done

for ip in $(awk -F ";" '{print $3}' $VM_DYN_ADDR); do ssh -o StrictHostKeyChecking=no root@$ip 'reboot'; done
```

#### Check cluster nodes static ip address

> :warning: Wait for cluster nodes to be up and display it static address in the **3rd column**

> :information_source: Run this on ESX

```
watch -n 5 "./getVMAddress.sh"
```

> :bulb: Leave watch with **Ctrl + c** 

:checkered_flag::checkered_flag::checkered_flag:

## Prepare Install OCP

### Create and copy First Master public key to cluster nodes

> :information_source: Run this on First Master

```
OCP="ocp1"
```


```
cat >> ~/.bashrc << EOF

export OCP=$OCP
export SSHPASS=spcspc
alias l='ls -Alhtr'

EOF

source ~/.bashrc

[ -z $(command -v sshpass) ] && yum install -y sshpass || echo sshpass installed

yes y | ssh-keygen -b 4096 -f ~/.ssh/id_rsa -N ""

for node in m1 w1 w2 w3; do sshpass -e ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$node-$OCP; done

```

### Check cluster nodes are time synchronized and Redhat subscribed

> :information_source: Run this on First Master

```
for node in m1 w1 w2 w3; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; date; timedatectl | grep "Local time"; yum repolist'; done
```

### Configure ansible inventory file

>:warning: **Read comments** in **hosts-cluster** and **adapt inventory file settings** before proceeding.

> :information_source: Run this on First Master

```
WEB_SERVER_URL="http://web/soft"
wget -c $WEB_SERVER_URL/hosts-cluster

sed 's/\([\.-]\)ocp./\1'$OCP'/g' hosts-cluster > /etc/ansible/hosts
grep -e 'ocp[0-9]\{1,\}' /etc/ansible/hosts
```

### Check ansible can speak with every cluster nodes

> :information_source: Run this on First Master

	ansible OSEv3 -m ping

### Check every cluster nodes can speak to registry.redhat.io

> :information_source: Run this on First Master

	ansible nodes -a 'ping -c 2 registry.redhat.io'

### Set ansible hosts with you Redhat partner credential

> :warning: Escape **'$'** character in your password if necessary.

> e.g. OREG_PWD="mypa\\\$sword"

> :information_source: Run this on First Master

```
OREG_ID="iicparis"
OREG_PWD=""
```


```
sed -i 's/\(oreg_auth_user=\).*$/\1'$OREG_ID'/' /etc/ansible/hosts
sed -i 's/\(oreg_auth_password=\).*$/\1'$OREG_PWD'/' /etc/ansible/hosts
```

#### Check ansible access to Redhat docker registry

> :warning: docker login should return **Login Succeeded**

> :information_source: Run this on First Master

```
OREG=$(docker info | awk -F ': https://' '$1 ~ "Registry" {print $2}' | awk -F '/' '{print $1}') && echo $OREG
OREG_ID=$(cat /etc/ansible/hosts | awk -F'=' '$1 ~ "^oreg_auth_user" {print $2}') && echo $OREG_ID
OREG_PWD=$(cat /etc/ansible/hosts | awk -F'=' '$1 ~ "^oreg_auth_password" {print $2}') && echo $OREG_PWD

docker login -u $OREG_ID -p $OREG_PWD $OREG
```
> :bulb: A new entry should have been added to **~/.docker/config.json** 

<br>

> :warning: Skopeo should return informations about **ose-docker-registry** image

> :information_source: Run this on First Master

```
[ ! -z $(command -v skopeo) ] && echo skopeo installed || yum install skopeo -y

skopeo inspect --tls-verify=false --creds=$OREG_ID:$OREG_PWD docker://$OREG/openshift3/ose-docker-registry:latest
```
:checkered_flag::checkered_flag::checkered_flag:

## Make a BeforeInstallingOCP snapshot

> :information_source: Run this on ESX

```
vim-cmd vmsvc/getallvms | awk '$2 ~ "[mw][1-5]|lb|cli|nfs|ctl" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.shutdown " $1}' | sh
sleep 10
vim-cmd vmsvc/getallvms | awk '$2 ~ "[mw][1-5]|lb|cli|nfs|ctl" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh

SNAPNAME="BeforeInstallingOCP"
vim-cmd vmsvc/getallvms | awk '$2 ~ "[mw][1-5]|lb|cli|nfs|ctl" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.create " $1 " '$SNAPNAME' "}' | sh
vim-cmd vmsvc/getallvms | awk '$2 ~ "[mw][1-5]|lb|cli|nfs|ctl" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh
```
:checkered_flag::checkered_flag::checkered_flag:

## Install OCP

### Check ansible can speak with cluster nodes

> :information_source: Run this on First Master

```
ansible OSEv3 -m ping
```

### Launch OCP installation

> :bulb: To avoid network failure, launch installation on **locale console** or in a **screen**

> :information_source: Run this on FIrst Master

```
[ ! -z $(command -v screen) ] && echo screen installed || yum install screen -y

pkill screen; screen -mdS ADM && screen -r ADM
```

### Launch prerequisites playbook

> :information_source: Run this on FIrst Master

```
cd /usr/share/ansible/openshift-ansible && ansible-playbook playbooks/prerequisites.yml
```

### Launch deploy_cluster playbook

> :information_source: Run this on FIrst Master

```
ansible-playbook playbooks/deploy_cluster.yml
```

<br>

:hourglass_flowing_sand: :smoking::coffee::smoking::coffee::smoking::coffee::smoking: :coffee: :hourglass_flowing_sand: :beer::beer::beer::pill:  :zzz::zzz: :zzz::zzz: :zzz::zzz::hourglass_flowing_sand: :smoking::coffee: :toilet: :shower: :smoking: :coffee::smoking: :coffee: :smoking: :coffee: :hourglass: 

<br>

>:bulb: Leave screen with **Ctrl + a + d**

>:bulb: Come back with **screen -r ADM**

> :bulb: If something went wrong have a look at **~/openshift-ansible.log** and revert to **BeforeInstallingOCP** snapshot

> :information_source: Run this on ESX

```
vim-cmd vmsvc/getallvms | awk '$2 ~ "[mw][1-5]|lb|cli|nfs|ctl" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.shutdown " $1}' | sh

vim-cmd vmsvc/getallvms | awk '$2 ~ "[mw][1-5]|lb|cli|nfs|ctl" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh

SNAPNAME="BeforeInstallingOCP"
for vmid in $(vim-cmd vmsvc/getallvms | awk 'NR>1 && $2 ~ "[mw][1-5]||lb|cli|nfs|ctl" {print $1}'); do vim-cmd vmsvc/snapshot.get $vmid | grep -A 1 'Snapshot Name\s\{1,\}: '$SNAPNAME | awk -F' : ' 'NR>1 {print "vim-cmd vmsvc/snapshot.revert "'$vmid'" " $2 " suppressPowerOn"}' | sh; done
```

<br>

:checkered_flag::checkered_flag::checkered_flag:

## Post install OCP

### Give admin user cluster-admin role

> :information_source: Run this on First Master

```
oc login -u system:admin

oc create clusterrolebinding registry-controller --clusterrole=cluster-admin --user=admin
```


### Check install

#### Login to cluster

> :information_source: Run this on First Master

```
oc login https://m1-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true
```

### Check Environment health

> :bulb: If needed to add in your browser, OCP certificate authority  can be found in your first master **/etc/origin/master/ca.crt**.

#### Checking complete environment health

> :information_source: Run this on First Master

Proceed as describe [here](https://docs.openshift.com/container-platform/3.11/day_two_guide/environment_health_checks.html#day-two-guide-complete-deployment-health-check)

#### Checking Hosts Router Registry and Network connectivity

> :information_source: Run this on First Master

Proceed as describe [here](https://docs.openshift.com/container-platform/3.11/day_two_guide/environment_health_checks.html#day-two-guide-host-health)

:checkered_flag::checkered_flag::checkered_flag:

## Make a OCPInstalled snapshot

> :information_source: Run this on ESX

```
vim-cmd vmsvc/getallvms | awk '$2 ~ "[mw][1-5]|lb|cli|nfs|ctl" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.shutdown " $1}' | sh
watch -n 5 vim-cmd vmsvc/getallvms | awk '$2 ~ "[mw][1-5]|lb|cli|nfs|ctl" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh

SNAPNAME="OCPInstalled"
vim-cmd vmsvc/getallvms | awk '$2 ~ "[mw][1-5]|lb|cli|nfs|ctl" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.create " $1 " '$SNAPNAME' "}' | sh
vim-cmd vmsvc/getallvms | awk '$2 ~ "[mw][1-5]|lb|cli|nfs|ctl" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh
```

:checkered_flag::checkered_flag::checkered_flag:
