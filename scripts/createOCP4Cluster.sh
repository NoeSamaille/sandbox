#!/bin/sh

ME=${0##*/}
RED="\e[31m"
YELLOW="\e[33m"
LBLUE="\e[34m"
GREEN="\e[32m"
NC="\e[0m"

OCP=""
DATASTORE="/vmfs/volumes/V7000F-Volume-10TB"
#DATASTORE="/vmfs/volumes/datastore1"
VMS_PATH="$DATASTORE/$OCP"
ISO_PATH="/vmfs/volumes/datastore1/iso"
VMX="/vmfs/volumes/datastore1/vmdk/rhcos.vmx"

[ -z "$OCP" ] && { echo -e "$RED ERROR: OCP is empty. Exiting... $NC"; exit 1; }

BOOTSTRAP_VM="bs-$OCP"
#MASTERS_VM="m1-$OCP m2-$OCP m3-$OCP"
MASTERS_VM="m1-$OCP"
WORKERS_VM="w1-$OCP w2-$OCP w3-$OCP"                 
#WORKERS_VM="w1-$OCP w2-$OCP w3-$OCP w4-$OCP w5-$OCP"
#WORKERS_VM="w1-$OCP w2-$OCP"         
#WORKERS_VM="w3-$OCP w4-$OCP w5-$OCP"
BOOTSTRAP_STORAGE="120G"                 
BOOTSTRAP_VCPU="4"
BOOTSTRAP_RAM="16384"
MASTER_STORAGE="250G"
MASTER_VCPU="4"
MASTER_RAM="16384"
WORKER_STORAGE="250G"
WORKER_VCPU="16"
WORKER_RAM="65536"
BOOTSTRAP_VNC_PORT="5909"
MASTER_1ST_VNC_PORT="5901"
WORKER_1ST_VNC_PORT="5904"
#WORKER_1ST_VNC_PORT="5906"

createWorkersVm (){

VNC_PORT=$WORKER_1ST_VNC_PORT

for VM_NAME in $WORKERS_VM; do
	echo $VM_NAME
	[ ! -d $VMS_PATH/$VM_NAME ] && mkdir $VMS_PATH/$VM_NAME
	cp -v $VMX $VMS_PATH/$VM_NAME/$VM_NAME.vmx
	if [ $? -eq 0 ]; then
		sed -i -e 's/displayName = "[^"]*"/displayName = "'$VM_NAME'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/numvcpus = "[^"]*"/numvcpus = "'$WORKER_VCPU'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/memSize = "[^"]*"/memSize = "'$WORKER_RAM'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's!ide1:0.fileName = "[^"]*"!ide1:0.fileName = "'$ISO_PATH'/'$VM_NAME'.iso"!' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/RemoteDisplay.vnc.port = "[^"]*"/RemoteDisplay.vnc.port = "'$VNC_PORT'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		vim-cmd solo/registervm $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		let "VNC_PORT++"
	fi
done

}

createWorkersVmdk (){

for VM_NAME in $WORKERS_VM; do
	echo $VM_NAME
	if [ $? -eq 0 ]; then
		vmkfstools -c $WORKER_STORAGE $VMS_PATH/$VM_NAME/$VM_NAME.vmdk
	fi
done

}

addWorkersVmdk (){

for VM_NAME in $WORKERS_VM; do
    echo $VM_NAME
	VMID=$(vim-cmd vmsvc/getallvms | awk '{if (NR > 1) print $1 " " $2 }' | grep $VM_NAME | awk '{print $1}')

	if [ ! -z "$VMID" ]; then
		vim-cmd vmsvc/device.diskaddexisting $VMID $VMS_PATH/$VM_NAME/$VM_NAME.vmdk 0 0
	fi;
done

}


createMastersVm (){

VNC_PORT=$MASTER_1ST_VNC_PORT

for VM_NAME in $MASTERS_VM; do
	echo $VM_NAME
	[ ! -d $VMS_PATH/$VM_NAME ] && mkdir $VMS_PATH/$VM_NAME
	cp -v $VMX $VMS_PATH/$VM_NAME/$VM_NAME.vmx
	if [ $? -eq 0 ]; then
		sed -i -e 's/displayName = "[^"]*"/displayName = "'$VM_NAME'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/numvcpus = "[^"]*"/numvcpus = "'$MASTER_VCPU'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/memSize = "[^"]*"/memSize = "'$MASTER_RAM'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's!ide1:0.fileName = "[^"]*"!ide1:0.fileName = "'$ISO_PATH'/'$VM_NAME'.iso"!' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/RemoteDisplay.vnc.port = "[^"]*"/RemoteDisplay.vnc.port = "'$VNC_PORT'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		vim-cmd solo/registervm $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		let "VNC_PORT++"
	fi
done

}

createMastersVmdk (){

for VM_NAME in $MASTERS_VM; do
	echo $VM_NAME
	if [ $? -eq 0 ]; then
		vmkfstools -c $MASTER_STORAGE $VMS_PATH/$VM_NAME/$VM_NAME.vmdk
	fi
done

}

addMastersVmdk (){

for VM_NAME in $MASTERS_VM; do
    echo $VM_NAME
	VMID=$(vim-cmd vmsvc/getallvms | awk '{if (NR > 1) print $1 " " $2 }' | grep $VM_NAME | awk '{print $1}')

	if [ ! -z "$VMID" ]; then
		vim-cmd vmsvc/device.diskaddexisting $VMID $VMS_PATH/$VM_NAME/$VM_NAME.vmdk 0 0
	fi;
done

}

createBootstrapVm (){

VNC_PORT=$BOOTSTRAP_VNC_PORT

for VM_NAME in $BOOTSTRAP_VM; do
	echo $VM_NAME
	[ ! -d $VMS_PATH/$VM_NAME ] && mkdir $VMS_PATH/$VM_NAME
	cp -v $VMX $VMS_PATH/$VM_NAME/$VM_NAME.vmx
	if [ $? -eq 0 ]; then
		sed -i -e 's/displayName = "[^"]*"/displayName = "'$VM_NAME'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/numvcpus = "[^"]*"/numvcpus = "'$BOOTSTRAP_VCPU'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/memSize = "[^"]*"/memSize = "'$BOOTSTRAP_RAM'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's!ide1:0.fileName = "[^"]*"!ide1:0.fileName = "'$ISO_PATH'/'$VM_NAME'.iso"!' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/RemoteDisplay.vnc.port = "[^"]*"/RemoteDisplay.vnc.port = "'$VNC_PORT'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		vim-cmd solo/registervm $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		let "VNC_PORT++"
	fi
done

}

createBootstrapVmdk (){

for VM_NAME in $BOOTSTRAP_VM; do
	echo $VM_NAME
	if [ $? -eq 0 ]; then
		vmkfstools -c $BOOTSTRAP_STORAGE $VMS_PATH/$VM_NAME/$VM_NAME.vmdk
	fi
done

}

addBootstrapVmdk (){

for VM_NAME in $BOOTSTRAP_VM; do
    echo $VM_NAME
	VMID=$(vim-cmd vmsvc/getallvms | awk '{if (NR > 1) print $1 " " $2 }' | grep $VM_NAME | awk '{print $1}')

	if [ ! -z "$VMID" ]; then
		vim-cmd vmsvc/device.diskaddexisting $VMID $VMS_PATH/$VM_NAME/$VM_NAME.vmdk 0 0
	fi;
done

}


case $1 in

	bootstrap)
		echo "Create $OCP bootstrap..."
		createBootstrapVm
		createBootstrapVmdk
		addBootstrapVmdk
		;;

	masters)
		echo "Create $OCP masters..."
		createMastersVm
		createMastersVmdk
		addMastersVmdk
		;;

	workers)
		echo "Create $OCP workers..."
		createWorkersVm
		createWorkersVmdk
		addWorkersVmdk
		;;

	*)
		echo "Create $OCP cluster..."
		createBootstrapVm
		createBootstrapVmdk
		addBootstrapVmdk
		createMastersVm
		createWorkersVm
		createMastersVmdk
		createWorkersVmdk
		addMastersVmdk
		addWorkersVmdk
		;;

esac

exit 0;
