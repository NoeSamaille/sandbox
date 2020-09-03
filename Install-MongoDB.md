# Install MongoDB

## Hardware requirements

-  One computer which will be called **Installer** that runs Linux or MacOS.

## System requirements

- Have completed  [Prepare for MongoDB](https://github.com/bpshparis/sandbox/blob/master/Prepare-for-MongoDB.md#prepare-for-mongodb)
- One **WEB server** where following files are available in **read mode**:
  - [mongodb-3.0.1-x86_64.tar](https://github.com/bpshparis/sandbox/blob/master/Prepare-for-MongoDB.md#save-mongodb-downloads-to-web-server)

<br>
:checkered_flag::checkered_flag::checkered_flag:
<br>

## Install MongoDB

> :information_source: Commands below are valid for a **Linux/Centos 7**.

> :warning: Some of commands below will need to be adapted to fit Linux/Debian or MacOS .

### Log in OCP

> :warning: Adapt settings to fit to your environment.

> :information_source: Run this on Installer 

```
LB_HOSTNAME="cli-ocp15"
NS="cpd"
```

```
oc login https://$LB_HOSTNAME:6443 -u admin -p admin --insecure-skip-tls-verify=true -n $NS
```

### Copy MongoDB Downloads from web server

> :warning: Adapt settings to fit to your environment.

> :information_source: Run this on Installer 

```
INST_DIR=~/cpd
ASSEMBLY="mongodb"
VERSION="3.0.1"
ARCH="x86_64"
TAR_FILE="$ASSEMBLY-$VERSION-$ARCH.tar"
WEB_SERVER_CP_URL="http://web/cloud-pak/assemblies"
```

```
[ -d "$INST_DIR" ] && { rm -rf $INST_DIR; mkdir $INST_DIR; } || mkdir $INST_DIR
cd $INST_DIR

mkdir bin && cd bin
wget -c $WEB_SERVER_CP_URL/$TAR_FILE
tar xvf $TAR_FILE
rm -f $TAR_FILE
```

### Push MongoDB images to Openshift registry

> :warning: To avoid network failure, launch installation on locale console or in a screen

> :information_source: Run this on Installer

```
[ ! -z $(command -v screen) ] && echo screen installed || yum install screen -y

pkill screen; screen -mdS ADM && screen -r ADM
```

> :warning: Adapt settings to fit to your environment.

> :information_source: Run this on Installer

```
INST_DIR=~/cpd
ASSEMBLY="mongodb"
ARCH="x86_64"
VERSION=$(find $INST_DIR/bin/cpd-linux-workspace/assembly/$ASSEMBLY/$ARCH/* -type d | awk -F'/' '{print $NF}')

[ ! -z "$VERSION" ] && echo $VERSION "-> OK" || echo "ERROR: VERSION is not set."
```

```
podman login -u $(oc whoami) -p $(oc whoami -t) $(oc registry info)

$INST_DIR/bin/cpd-linux preloadImages \
--assembly $ASSEMBLY \
--version $VERSION \
--arch $ARCH \
--action push \
--transfer-image-to $(oc registry info)/$(oc project -q) \
--target-registry-password $(oc whoami -t) \
--target-registry-username $(oc whoami) \
--load-from $INST_DIR/bin/cpd-linux-workspace \
--accept-all-licenses
```


### Create MongoDB resources on cluster

> :information_source: Run this on Installer

```
$INST_DIR/bin/cpd-linux adm \
--namespace $(oc project -q) \
--assembly $ASSEMBLY \
--version $VERSION \
--arch $ARCH \
--load-from $INST_DIR/bin/cpd-linux-workspace \
--apply \
--accept-all-licenses
```

>:bulb: Check following services account have been created
>
>-  mongodb-enterprise-appdb
>-  mongodb-enterprise-database-pods
>-  mongodb-enterprise-ops-manager
>-  mongodb-sa

```
oc get sa
```


### Install MongoDB

> :warning: Adapt settings to fit to your environment.

> :information_source: Run this on Installer

```
SC="portworx-db-gp3"
INT_REG=$(oc registry info --internal)
```


```
$INST_DIR/bin/cpd-linux \
--namespace $(oc project -q) \
--assembly $ASSEMBLY \
--version $VERSION \
--arch $ARCH \
--storageclass $SC \
--cluster-pull-prefix $INT_REG/$(oc project -q) \
--load-from $INST_DIR/bin/cpd-linux-workspace \
--accept-all-licenses

```

### Check MongoDB status

> :information_source: Run this on Installer

```
$INST_DIR/bin/cpd-linux status \
--namespace $(oc project -q) \
--assembly $ASSEMBLY \
--arch $ARCH
```

![](img/mongodb-ready.jpg)

<br>
:checkered_flag::checkered_flag::checkered_flag:
<br>

### Create MongoDB database

#### Access Cloud Pak for Data web console

> :information_source: Run this on Installer

```
oc get routes | awk 'NR==2 {print "Access the web console at https://" $2}'
```

> :bulb: Login as **admin** using **password** for password 

### Creating MongoDB database

> :information_source: Run this on Cloud Pak for Data web console

![](img/menu-collect-mydata.jpg)

1.   From the navigation, select Collect > My data.     
2.   Open the Databases tab, which is only visible after you install the database service.
3.   Click Create a database.
4.   Select the database type and version. Click Next. 
5.   Keep **default value** for **Configure**.
5.   Leave **Deploy database on dedicated nodes** unchecked.
6.   Select **portworx-db-gp3** for System storage. 
7.   Select **portworx-db-gp3** for User storage. 
8.   Click on **Continue with defaults**. 
9.   Click on **Create**.

### Monitoring MongoDB database creation

#### Log in OCP

> :warning: Adapt settings to fit to your environment.

> :information_source: Run this on Installer 

```
LB_HOSTNAME="cli-ocp15"
NS="cpd"
```

```
oc login https://$LB_HOSTNAME:6443 -u admin -p admin --insecure-skip-tls-verify=true -n $NS
```

#### Monitoring MongoDB database creation

> :information_source: Run this on Installer 

```
watch -n5 "oc get pvc | egrep -w 'mongodb'; oc get po | egrep -w 'mongodb'"
```

#### Check MongoDB database status

> :information_source: Run this on Cloud Pak for Data web console

1.   From the navigation, select Collect > My data.     

![](img/mongodb-database-ok.jpg)

### Accessing MongoDB Enterprise Advanced Ops Manager

#### Obtain the default user credentials for MongoDB Enterprise Advanced Ops Manager

> :information_source: Run this on Cloud Pak for Data web console

![](img/menu-collect-mydata.jpg)

1. From the navigation, select Collect > My data. 
2. Open the Databases tab.
3. Open the actions menu for the database that you want to connect to and select **Details**
4. Get credentials in the **MongoDB Enterprise Advanced Ops Manager section** of the Database details page.. 

#### Get MongoDB Enterprise Advanced Ops Manager route

> :information_source: Run this on Installer 

```
NS="cpd"

oc get routes -n $NS | grep mongodb | awk '{print "http://" $2}'
```

<br>
:checkered_flag::checkered_flag::checkered_flag:
<br>