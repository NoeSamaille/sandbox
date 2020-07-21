# Installing Redhat Openshift 4.3 on Bare Metal


## Redhat requirements

Be a [Redhat partner](https://partnercenter.redhat.com/Dashboard_page).



## Hardware requirements

One Lenovo **X3550M5** or similar to host **5** virtual machines (bootstrap will be removed after cluster install):

| name                        | role                  | vcpus  | ram (GB) | storage (GB) | ethernet (10GB) |
| --------------------------- | --------------------- | ------ | -------- | ------------ | --------------- |
| cli-ocp5.iicparis.fr.ibm.com | load balancer + installer | 4      | 16 | 250          | 1               |
| m1-ocp5.iicparis.fr.ibm.com | master + etcd              | 4      | 16 | 250          | 1               |
| w1-ocp5.iicparis.fr.ibm.com | worker                | 16     | 64       | 250          | 1               |
| w2-ocp5.iicparis.fr.ibm.com | worker                | 16     | 64       | 250          | 1               |
| w3-ocp5.iicparis.fr.ibm.com | worker                | 16     | 64       | 250          | 1               |
| bs-ocp5.iicparis.fr.ibm.com | bootstrap (will be removed after cluster install) | 4     | 16       | 120          | 1               |
| **TOTAL**                   |                       | **56** | **224** | **1250**   | **5**          |


## System requirements

- One **VMware vSphere Hypervisor** [5.5](https://my.vmware.com/en/web/vmware/evalcenter?p=free-esxi5), [6.7](https://my.vmware.com/en/web/vmware/evalcenter?p=free-esxi6) or [7.0](https://my.vmware.com/en/web/vmware/evalcenter?p=free-esxi7) with **ESXi Shell access enabled**. VCenter is NOT required.

- Two **vmdk (centos.vmdk and centos-flat.vmdk)** file who host  a [minimal Centos 7](https://docs.centos.org/en-US/centos/install-guide/Simple_Installation/) **booting in dhcp**, **running VMware Tools** with **localhost.localdomain** as hostname. 

- One **DNS server**.
- One **DHCP server**.
- One **WEB server** where following files are available in **read mode**:

  - [pull-secret.txt](https://cloud.redhat.com/openshift/install/pull-secret)
  - [OpenShift installer](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-linux.tar.gz)
  - [Command line interface](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz)
  - [Red Hat Enterprise Linux CoreOS (RHCOS)](https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/latest/)
  - [install-config.yaml](scripts/install-config.yaml)
  - centos.vmdk
  - centos-flat.vmdk
  - [rhel.vmx](scripts/rhel.vmx)
  - [rhcos.vmx](scripts/rhcos.vmx)
  - [createCli.sh](scripts/createCli.sh)
  - [createOCP4Cluster.sh](scripts/createOCP3Cluster.sh)
  - [setHostAndIP.sh](scripts/setHostAndIP.sh)
  - [extendRootLV.sh](scripts/extendRootLV.sh)
  - [getVMAddress.sh](scripts/getVMAddress.sh)
  - [buildIso.sh](scripts/buildIso.sh)

:checkered_flag::checkered_flag::checkered_flag:

## Add DNS records

> :information_source: Run this on DNS

```
DOMAIN=$(cat /etc/resolv.conf | awk '$1 ~ "search" {print $2}') && echo $DOMAIN
IP_HEAD="172.16"
OCP=ocp5
CLI_IP=$IP_HEAD.187.50
M1_IP=$IP_HEAD.187.51
W1_IP=$IP_HEAD.187.54
W2_IP=$IP_HEAD.187.55
W3_IP=$IP_HEAD.187.56
BS_IP=$IP_HEAD.187.59
MZONE=/var/lib/bind/$DOMAIN.hosts
RZONE=/var/lib/bind/$IP_HEAD.rev
```
### Add records to master zone

> :information_source: Run this on DNS

```
cat >> $MZONE << EOF
cli-$OCP.$DOMAIN.   IN      A       $CLI_IP
m1-$OCP.$DOMAIN.   IN      A       $M1_IP
w1-$OCP.$DOMAIN.   IN      A       $W1_IP
w2-$OCP.$DOMAIN.   IN      A       $W2_IP
w3-$OCP.$DOMAIN.   IN      A       $W3_IP
bs-$OCP.$DOMAIN.   IN      A       $BS_IP
api.$OCP.$DOMAIN.  IN      A       $CLI_IP
api-int.$OCP.$DOMAIN.      IN      A       $CLI_IP
apps.$OCP.$DOMAIN. IN      A       $CLI_IP
etcd-0.$OCP.$DOMAIN.       IN      A       $M1_IP
*.apps.$OCP.$DOMAIN.       IN      CNAME   apps.$OCP.$DOMAIN.
_etcd-server-ssl._tcp.$OCP.$DOMAIN.        86400   IN      SRV     0 10 2380 etcd-0.$OCP.$DOMAIN.
EOF
```

### Add records to reverse zone

> :information_source: Run this on DNS

```
cat >> $RZONE << EOF
$(echo $CLI_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     cli-$OCP.$DOMAIN.
$(echo $M1_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     m1-$OCP.$DOMAIN.
$(echo $W1_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     w1-$OCP.$DOMAIN.
$(echo $W2_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     w2-$OCP.$DOMAIN.
$(echo $W3_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     w3-$OCP.$DOMAIN.
$(echo $BS_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     bs-$OCP.$DOMAIN.
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
for host in m1 w1 w2 w3 bs; do echo -n $host-$OCP "-> "; dig @localhost +short $host-$OCP.$DOMAIN; done
```

### Test reverse zone

> :information_source: Run this on DNS

```
for host in m1 w1 w2 w3 bs; do IP=$(dig @localhost +short $host-$OCP.$DOMAIN); echo -n $IP "-> "; dig @localhost +short -x $IP; done
```

### Test alias

> :information_source: Run this on DNS

```
dig @localhost +short *.apps.$OCP.iicparis.fr.ibm.com
```

### Test service

> :information_source: Run this on DNS

```
dig @localhost +short _etcd-server-ssl._tcp.$OCP.$DOMAIN SRV
```

:checkered_flag::checkered_flag::checkered_flag:


## Create Cli

### Download necessary stuff

> :information_source: Run this on ESX

```
WEB_SERVER_VMDK_URL="http://web/vmdk"
WEB_SERVER_SOFT_URL="http://web/soft"
VMDK_PATH="/vmfs/volumes/datastore1/vmdk/"
```

```
wget -c $WEB_SERVER_VMDK_URL/centos-gui-flat.vmdk -P $VMDK_PATH
wget -c $WEB_SERVER_VMDK_URL/centos-gui.vmdk -P $VMDK_PATH
wget -c $WEB_SERVER_VMDK_URL/rhel.vmx -P $VMDK_PATH
wget -c $WEB_SERVER_SOFT_URL/createCli.sh
```

### Create Cli

>:warning: Set **OCP**, **DATASTORE**, **VMS_PATH**, **CENTOS_VMDK** and **VMX** variables accordingly in **createCli.sh** before proceeding.

> :information_source: Run this on ESX

```
chmod +x ./createCli.sh
./createCli.sh
```

### Start Cli

> :information_source: Run this on ESX

```
PATTERN="cli"
vim-cmd vmsvc/getallvms | awk '$2 ~ "'$PATTERN'" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh
vim-cmd vmsvc/getallvms | awk '$2 ~ "'$PATTERN'" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh
```

### Get Cli dhcp address

> :information_source: Run this on ESX

```
CLI_DYN_ADDR="cli-addresse"
wget -c $WEB_SERVER_SOFT_URL/getVMAddress.sh
```

> :warning: Set **IP_HEAD** variables accordingly in **getVMAddress.sh** before proceeding.

> :information_source: Run this on ESX

```
chmod +x ./getVMAddress.sh
watch -n 5 "./getVMAddress.sh | tee $CLI_DYN_ADDR"
```

> :bulb: Wait for Cli to be up and display its dhcp address in the **3rd column**

> :bulb: Leave watch with **Ctrl + c**

### Configure Cli 

#### Download necessary stuff

> :information_source: Run this on ESX

```
WEB_SERVER_SOFT_URL="http://web/soft"

wget -c $WEB_SERVER_SOFT_URL/setHostAndIP.sh 
chmod +x setHostAndIP.sh
wget -c $WEB_SERVER_SOFT_URL/extendRootLV.sh
chmod +x extendRootLV.sh
```

#### Create and copy ESX public key to Cli

> :warning: To be able to ssh from ESX you need to enable sshClient rule outgoing port

> :information_source: Run this on ESX

```
esxcli network firewall ruleset set -e true -r sshClient
```

> :information_source: Run this on ESX

```
[ ! -d "/.ssh" ] && mkdir /.ssh || echo /.ssh already exists

/usr/lib/vmware/openssh/bin/ssh-keygen -t rsa -b 4096 -N "" -f /.ssh/id_rsa

for ip in $(awk -F ";" '{print $3}' $CLI_DYN_ADDR); do cat /.ssh/id_rsa.pub | ssh -o StrictHostKeyChecking=no root@$ip '[ ! -d "/root/.ssh" ] && mkdir /root/.ssh && cat >> /root/.ssh/authorized_keys'; done
```

#### Extend Cli Root logical volume

>:warning: Set **DISK**, **PART**, **VG** and **LV** variables accordingly in **extendRootLV.sh** before proceeding.

> :information_source: Run this on ESX

```
for ip in $(awk -F ";" '{print $3}' $CLI_DYN_ADDR); do echo "copying extendRootLV.sh to" $ip "..."; scp -o StrictHostKeyChecking=no extendRootLV.sh root@$ip:/root; done

for ip in $(awk -F ";" '{print $3}' $CLI_DYN_ADDR); do ssh -o StrictHostKeyChecking=no root@$ip 'hostname -f; /root/extendRootLV.sh'; done
```

#### Set Cli static ip address and reboot Cli

> :information_source: Run this on ESX

```
for ip in $(awk -F ";" '{print $3}' $CLI_DYN_ADDR); do echo "copy to" $ip; scp -o StrictHostKeyChecking=no setHostAndIP.sh root@$ip:/root; done

for LINE in $(awk -F ";" '{print $0}' $CLI_DYN_ADDR); do  HOSTNAME=$(echo $LINE | cut -d ";" -f2); IPADDR=$(echo $LINE | cut -d ";" -f3); echo $HOSTNAME; echo $IPADDR; ssh -o StrictHostKeyChecking=no root@$IPADDR '/root/setHostAndIP.sh '$HOSTNAME; done

for ip in $(awk -F ";" '{print $3}' $CLI_DYN_ADDR); do ssh -o StrictHostKeyChecking=no root@$ip 'reboot'; done
```

#### Check Cli static ip address

> :warning: Wait for cluster nodes to be up and display it static address in the **3rd column**

> :information_source: Run this on ESX

```
watch -n 5 "./getVMAddress.sh"
```

> :bulb: Leave watch with **Ctrl + c** 

:checkered_flag::checkered_flag::checkered_flag:


## Install load balancer

### Set env variables

> :information_source: Run this on Cli

```
OCP="ocp5"
```

```
cat >> ~/.bashrc << EOF

export OCP=$OCP
export SSHPASS=spcspc
alias l='ls -Alhtr'

EOF

source ~/.bashrc
```

### Disable security

> :information_source: Run this on Cli

```
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i -e 's/^SELINUX=\w*/SELINUX=disabled/' /etc/selinux/config
```

### Install load balancer

> :information_source: Run this on Cli

```
yum install haproxy -y
```

### Configure load balancer

> :information_source: Run this on Cli

```
DOMAIN=$(cat /etc/resolv.conf | awk '$1 ~ "^search" {print $2}') && echo $DOMAIN
LB_CONF="/etc/haproxy/haproxy.cfg" && echo $LB_CONF
```

```
sed -i '/^\s\{1,\}maxconn\s\{1,\}3000$/q' $LB_CONF

cat >> $LB_CONF << EOF

listen stats
    bind :9000
    mode http
    stats enable
    stats uri /

frontend ingress-http
    bind *:80
    default_backend ingress-http
    mode tcp
    option tcplog

backend ingress-http
    balance source
    mode tcp
    server w1-$OCP $(dig +short w1-$OCP.$DOMAIN):80 check
    server w2-$OCP $(dig +short w2-$OCP.$DOMAIN):80 check
    server w3-$OCP $(dig +short w3-$OCP.$DOMAIN):80 check
    # server w4-$OCP $(dig +short w4-$OCP.$DOMAIN):80 check
    # server w5-$OCP $(dig +short w5-$OCP.$DOMAIN):80 check

frontend ingress-https
    bind *:443
    default_backend ingress-https
    mode tcp
    option tcplog

backend ingress-https
    balance source
    mode tcp
    server w1-$OCP $(dig +short w1-$OCP.$DOMAIN):443 check
    server w2-$OCP $(dig +short w2-$OCP.$DOMAIN):443 check
    server w3-$OCP $(dig +short w3-$OCP.$DOMAIN):443 check
    # server w4-$OCP $(dig +short w4-$OCP.$DOMAIN):443 check
    # server w5-$OCP $(dig +short w5-$OCP.$DOMAIN):443 check

frontend openshift-api-server
    bind *:6443
    default_backend openshift-api-server
    mode tcp
    option tcplog

backend openshift-api-server
    balance source
    mode tcp
    server m1-$OCP $(dig +short m1-$OCP.$DOMAIN):6443 check
    # server m2-$OCP $(dig +short m2-$OCP.$DOMAIN):6443 check
    # server m3-$OCP $(dig +short m3-$OCP.$DOMAIN):6443 check
    server bs-$OCP $(dig +short bs-$OCP.$DOMAIN):6443 check

frontend machine-config-server
    bind *:22623
    default_backend machine-config-server
    mode tcp
    option tcplog

backend machine-config-server
    balance source
    mode tcp
    server m1-$OCP $(dig +short m1-$OCP.$DOMAIN):22623 check
    # server m2-$OCP $(dig +short m2-$OCP.$DOMAIN):22623 check
    # server m3-$OCP $(dig +short m3-$OCP.$DOMAIN):22623 check
    server bs-$OCP $(dig +short bs-$OCP.$DOMAIN):22623 check

EOF
```

### Start  load balancer

> :information_source: Run this on Cli

```
systemctl restart haproxy
systemctl enable haproxy
RC=$(curl -I http://cli-$OCP:9000 | awk 'NR==1 {print $3}') && echo $RC
```
:checkered_flag::checkered_flag::checkered_flag:


## Prepare installing OCP 4.3

### Set install-config.yaml

> :information_source: Run this on Cli 

```
DOMAIN=$(cat /etc/resolv.conf | awk '$1 ~ "^search" {print $2}') && echo $DOMAIN
WEB_SERVER_SOFT_URL="http://web/soft"
INST_DIR=~/ocpinst && echo $INST_DIR
```

```
[ -d "$INST_DIR" ] && rm -rf $INST_DIR/* || mkdir $INST_DIR
cd $INST_DIR

wget -c $WEB_SERVER_SOFT_URL/install-config.yaml
sed -i '10s/.*/  replicas: 1/'  install-config.yaml
sed -i "s/\(^baseDomain: \).*$/\1$DOMAIN/" install-config.yaml
sed -i -e '12s/^  name:.*$/  name: '$OCP'/' install-config.yaml

wget $WEB_SERVER_SOFT_URL/pull-secret.txt
SECRET=$(cat pull-secret.txt) && echo $SECRET
sed -i "s/^pullSecret:.*$/pullSecret: '$SECRET'/"  install-config.yaml

[ ! -f ~/.ssh/id_rsa ] && yes y | ssh-keygen -b 4096 -f ~/.ssh/id_rsa -N ""
PUB_KEY=$(cat ~/.ssh/id_rsa.pub) && echo $PUB_KEY
sed -i "s:^sshKey\:.*$:sshKey\: '$PUB_KEY':"  install-config.yaml 
```

### Backup install-config.yaml on web server

> :information_source: Run this on Cli 

```
WEB_SERVER="web"
WEB_SERVER_PATH="/web/$OCP"
```

```
[ -z $(command -v sshpass) ] && yum install -y sshpass || echo "sshpass already installed"

sshpass -e ssh -o StrictHostKeyChecking=no root@$WEB_SERVER "rm -rf $WEB_SERVER_PATH"

sshpass -e ssh -o StrictHostKeyChecking=no root@$WEB_SERVER "mkdir $WEB_SERVER_PATH"

sshpass -e scp -o StrictHostKeyChecking=no install-config.yaml root@$WEB_SERVER:$WEB_SERVER_PATH

sshpass -e ssh -o StrictHostKeyChecking=no root@$WEB_SERVER "chmod -R +r $WEB_SERVER_PATH"
```

### Install Openshift installer, oc and kubectl commands

> :information_source: Run this on Cli 

```
WEB_SERVER_SOFT_URL="http://web/soft"
INSTALLER_FILE="openshift-install-linux-4.3.18.tar.gz"
CLIENT_FILE="oc-4.3.18-linux.tar.gz"
```

```
cd $INST_DIR

wget -c $WEB_SERVER_SOFT_URL/$INSTALLER_FILE
tar xvzf $INSTALLER_FILE

wget -c $WEB_SERVER_SOFT_URL/$CLIENT_FILE
tar -xvzf $CLIENT_FILE -C $(echo $PATH | awk -F":" 'NR==1 {print $1}')
```

### Create manifest and ignition files

> :warning: You have to be on line to execute this step.

> :information_source: Run this on Cli 

```
cd $INST_DIR

./openshift-install create manifests --dir=$PWD
sed -i 's/mastersSchedulable: true/mastersSchedulable: false/' manifests/cluster-scheduler-02-config.yml

./openshift-install create ignition-configs --dir=$PWD
```

### Make ignition files and RHCOS image available on web server

> :information_source: Run this on Cli 

```
WEB_SERVER="web"
WEB_SERVER_PATH="/web/$OCP"
RHCOS_IMG_PATH="/web/img/rhcos-4.4.3-x86_64-metal.x86_64.raw.gz"
```

```
cd $INST_DIR

sshpass -e scp -o StrictHostKeyChecking=no *.ign root@$WEB_SERVER:$WEB_SERVER_PATH

sshpass -e ssh -o StrictHostKeyChecking=no root@$WEB_SERVER "ln -s $RHCOS_IMG_PATH $WEB_SERVER_PATH"

sshpass -e ssh -o StrictHostKeyChecking=no root@web "chmod -R +r /web/$OCP"
```

### Customize RHCOS iso

#### Prepare RHCOS iso customization

> :information_source: Run this on Cli 

```
WEB_SERVER_ISO_URL="http://web/iso"
RHCOS_ISO_FILE="rhcos-4.4.3-x86_64-installer.x86_64.iso"
ISO_PATH="/media/iso"
RW_ISO_PATH="/media/isorw"
```

```
wget -c $WEB_SERVER_ISO_URL/$RHCOS_ISO_FILE

[ ! -d $ISO_PATH ] && mkdir $ISO_PATH 

while [ ! -z "$(ls -A $ISO_PATH)" ]; do umount $ISO_PATH; sleep 2; done

mount -o loop $RHCOS_ISO_FILE $ISO_PATH

[ ! -d $RW_ISO_PATH ] && mkdir $RW_ISO_PATH || rm -rf $RW_ISO_PATH/*
```

#### Customize RHCOS iso 

> :information_source: Run this on Cli 

```
WEB_SERVER_SOFT_URL="http://web/soft"
```

```
wget -c $WEB_SERVER_SOFT_URL/buildIso.sh
chmod +x buildIso.sh
```

> :warning: Set **OCP**, **WEB_SRV_URL**, **RAW_IMG_URL**, **DNS**,  **DOMAIN**, **IF**, **MASK**, **GATEWAY**,  **ISO_PATH**, **RW_ISO_PATH** and **ISO_CFG** variables accordingly in **buildIso.sh** before proceeding.

> :information_source: Run this on Cli 

```
./buildIso.sh

while [ ! -z "$(ls -A $ISO_PATH)" ]; do umount $ISO_PATH; sleep 2; done
rmdir $ISO_PATH
```

#### Check RHCOS isolinux.cfg

> :information_source: Run this on Cli 

```
TEST_ISO_PATH="/media/test"
```

```
[ ! -d $TEST_ISO_PATH ] && mkdir $TEST_ISO_PATH

for iso in $(ls *.iso); do
    echo $iso
    mount -o loop $iso $TEST_ISO_PATH
    grep 'ip=' $TEST_ISO_PATH/isolinux/isolinux.cfg
    sleep 2
    umount $TEST_ISO_PATH
done

while [ ! -z "$(ls -A $TEST_ISO_PATH)" ]; do umount $TEST_ISO_PATH; sleep 2; done

rmdir $TEST_ISO_PATH
```

#### Make iso files available on ESX server

> :information_source: Run this on Cli

```
ESX_SERVER="ocp5"
ESX_ISO_PATH="/vmfs/volumes/datastore1/iso"
```

```
sshpass -e ssh -o StrictHostKeyChecking=no root@$ESX_SERVER "rm -rf $ESX_ISO_PATH/*-$OCP.iso"

sshpass -e scp -o StrictHostKeyChecking=no *-$OCP.iso root@$ESX_SERVER:/$ESX_ISO_PATH

sshpass -e ssh -o StrictHostKeyChecking=no root@$ESX_SERVER "chmod -R +r $ESX_ISO_PATH"
```


## Create Cluster

### Download necessary stuff

> :information_source: Run this on ESX

```
WEB_SERVER_SOFT_URL="http://web/soft"
WEB_SERVER_VMDK_URL="http://web/vmdk"
VMDK_PATH="/vmfs/volumes/datastore1/vmdk/"
```

```
wget -c $WEB_SERVER_SOFT_URL/createOCP4Cluster.sh
wget -c $WEB_SERVER_VMDK_URL/rhcos.vmx -P $VMDK_PATH
```

### Create cluster nodes

>:warning: Set **OCP**, **DATASTORE**, **VMS_PATH**, **ISO_PATH** and **VMX** variables accordingly in **createOCP4Cluster.sh** before proceeding.

> :information_source: Run this on ESX

```
chmod +x ./createOCP4Cluster.sh
./createOCP4Cluster.sh
```

> :warning: For VNC to work run this on ESX:

> :information_source: Run this on ESX

```
esxcli network firewall ruleset set -e true -r gdbserver
```


## Make a BeforeInstallingOCP snapshot

> :information_source: Run this on ESX

```
PATTERN="[mw][1-5]|cli|bs"
SNAPNAME="BeforeInstallingOCP"
```

```
vim-cmd vmsvc/getallvms | awk '$2 ~ "'$PATTERN'" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.shutdown " $1}' | sh

sleep 10

vim-cmd vmsvc/getallvms | awk '$2 ~ "'$PATTERN'" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh

vim-cmd vmsvc/getallvms | awk '$2 ~ "'$PATTERN'" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.create " $1 " '$SNAPNAME' "}' | sh

vim-cmd vmsvc/getallvms | awk '$2 ~ "'$PATTERN'" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh
```
:checkered_flag::checkered_flag::checkered_flag:


## Install OCP

### Launch OCP installation

> :bulb: To avoid network failure, launch installation on **locale console** or in a **screen**

> :information_source: Run this on Cli

```
[ ! -z $(command -v screen) ] && echo screen installed || yum install screen -y

pkill screen; screen -mdS ADM && screen -r ADM
```

### Launch wait-for-bootstrap-complete playbook

> :information_source: Run this on Cli

```
INST_DIR=~/ocpinst
```

```
cd $INST_DIR

> ~/.ssh/known_hosts
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

./openshift-install --dir=$PWD wait-for bootstrap-complete --log-level=debug
```

<br>

:hourglass_flowing_sand: :smoking::coffee::smoking::coffee::smoking::coffee::smoking: :coffee: :hourglass_flowing_sand: :beer::beer::beer::pill:  :zzz::zzz: :zzz::zzz: :zzz::zzz::hourglass_flowing_sand: :smoking::coffee: :toilet: :shower: :smoking: :coffee::smoking: :coffee: :smoking: :coffee: :hourglass: 

<br>

>:bulb: Leave screen with **Ctrl + a + d**

>:bulb: Come back with **screen -r ADM**

>:bulb: bootstrap complete output

[](img/bscomplete.jpg)

### Launch wait-for-install-complete playbook

> :information_source: Run this on Cli

```
INST_DIR=~/ocpinst
```

```
cd $INST_DIR
./openshift-install --dir=$PWD wait-for install-complete
```

<br>

:hourglass_flowing_sand: :smoking::coffee::smoking::coffee::smoking::coffee::smoking: :coffee: :hourglass_flowing_sand: :beer::beer::beer::pill:  :zzz::zzz: :zzz::zzz: :zzz::zzz::hourglass_flowing_sand: :smoking::coffee: :toilet: :shower: :smoking: :coffee::smoking: :coffee: :smoking: :coffee: :hourglass: 

<br>

>:bulb: Leave screen with **Ctrl + a + d**

>:bulb: Come back with **screen -r ADM**

> :bulb: If something went wrong have a look at **~/$INST_DIR/.openshift_install.log** and revert to **BeforeInstallingOCP** snapshot

> :information_source: Run this on ESX

```
PATTERN="[mw][1-5]|cli"
SNAPNAME="BeforeInstallingOCP"
```

```
vim-cmd vmsvc/getallvms | awk '$2 ~ "'$PATTERN'" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.shutdown " $1}' | sh

sleep 10

vim-cmd vmsvc/getallvms | awk '$2 ~ "'$PATTERN'" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh

for vmid in $(vim-cmd vmsvc/getallvms | awk 'NR>1 && $2 ~ "'$PATTERN'" {print $1}'); do vim-cmd vmsvc/snapshot.get $vmid | grep -A 1 'Snapshot Name\s\{1,\}: '$SNAPNAME | awk -F' : ' 'NR>1 {print "vim-cmd vmsvc/snapshot.revert "'$vmid'" " $2 " suppressPowerOn"}' | sh; done
```

<br>

:checkered_flag::checkered_flag::checkered_flag:

## Post install OCP

### Create an admin userwith  cluster-admin role

> :information_source: Run this on Cli

```
INST_DIR=~/ocpinst
```

```
export KUBECONFIG=$INST_DIR/auth/kubeconfig
oc whoami
```
>:bulb: Command above should return **system:admin**


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
