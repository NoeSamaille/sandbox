# Install Cloud Pak for Data 3.0.1

## System requirements

- Have completed  [Prepare Redhat Openshift for Cloud Paks](https://github.com/bpshparis/sandbox/blob/master/Prepare-Redhat-Openshift-for-Cloud-Paks.md#prepare-redhat-openshift-for-cloud-paks)
- One **WEB server** where following files are available in **read mode**:
  - [cloudpak4data-ee-3.0.1.tgz](https://github.com/IBM/cpd-cli/releases/download/cpd-3.0.1/cloudpak4data-ee-3.0.1.tgz)
  - [IBM® Cloud Pak for Data entitlement license API key](https://myibm.ibm.com/products-services/containerlibrary) saved in apikey file.

:checkered_flag::checkered_flag::checkered_flag:

## Prepare installing Cloud Pak for Data

### Install the cpd command

> :information_source: Run this on Cli 

```
WEB_SERVER_CP_URL="http://web/cloud-pak"
INST_FILE="cloudpak4data-ee-3.0.1.tgz"
INST_DIR=~/cpd && echo $INST_DIR
```

```
[ -d "$INST_DIR" ] && rm -rf $INST_DIR/* || mkdir $INST_DIR
cd $INST_DIR

wget -c $WEB_SERVER_CP_URL/$INST_FILE
tar xvzf $INST_FILE
rm $INST_FILE -f
```

### Set repo.yaml

> :information_source: Run this on Cli 

```
WEB_SERVER_CP_URL="http://web/cloud-pak"
APIKEY_FILE="apikey"
```

```
wget -c $WEB_SERVER_CP_URL/$APIKEY_FILE
USERNAME="cp" && echo $USERNAME
APIKEY=$(cat $APIKEY_FILE) && echo $APIKEY

```

#### Test your entitlement key against Cloud Pak registry

> :information_source: Run this on Cli

```
REG="cp.icr.io"
```

```
docker login -u $USERNAME -p $APIKEY $REG
```

#### Add username and apikey to repo.yaml

> :information_source: Run this on Cli

```
sed -i -e 's/\(^\s\{4\}username:\).*$/\1 '$USERNAME'/' repo.yaml

sed -i -e 's/\(^\s\{4\}apikey:\).*$/\1 '$APIKEY'/' repo.yaml
```

### Log in OCP

> :information_source: Run this on **OCP 3.11** Cli

```
oc login https://cli-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true
```

> :information_source: Run this on **OCP 4.3** Cli

```
oc login https://cli-$OCP:6443 -u admin -p admin --insecure-skip-tls-verify=true
```

### Create Cloud Pak for Data project

> :information_source: Run this on Cli

```
PROJECT_ADMIN="admin"
```

```
oc new-project cpd

oc adm policy add-role-to-user cpd-admin-role $PROJECT_ADMIN --role-namespace=$(oc project -q) -n $(oc project -q)
```

### Download  Cloud Pak for Data resources definitions

> :warning: You have to be on line to execute this step.

> :information_source: Run this on Cli

```
ASSEMBLY="lite"
VERSION="3.0.1"
ARCH="x86_64"
NS=$(oc project -q)
```

```
$INST_DIR/bin/cpd-linux adm --repo $INST_DIR/repo.yaml --assembly $ASSEMBLY --arch $ARCH --namespace $NS --accept-all-licenses 
```

> : bulb:  **$INST_DIR/cpd-linux-workspace** have been created and populated with yaml files.

### Download  Cloud Pak for Data images

> :warning: You have to be on line to execute this step.

> :warning: To avoid network failure, launch installation on locale console or in a screen

> :information_source: Run this on Cli

```
[ ! -z $(command -v screen) ] && echo screen installed || yum install screen -y

pkill screen; screen -mdS ADM && screen -r ADM
```

> :information_source: Run this on Cli

```
ASSEMBLY="lite"
VERSION="3.0.1"
ARCH="x86_64"
NS=$(oc project -q)
```

```
$INST_DIR/bin/cpd-linux preloadImages --version $VERSION --action download -a $ASSEMBLY --arch $ARCH --repo $INST_DIR/repo.yaml --accept-all-licenses
```

> :bulb:  Images have been copied in **$INST_DIR/bin/cpd-linux-workspace/images/**
