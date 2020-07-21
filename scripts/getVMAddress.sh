#!/bin/sh

IP_HEAD="172.16.1"

for LINE in $(vim-cmd vmsvc/getallvms | awk '{if (NR > 1) print $1 ";" $2}'); do
        VMID=$(echo $LINE | cut -d ";" -f1);
        VMNAME=$(echo $LINE | cut -d ";" -f2);
        #VMIP=$(vim-cmd vmsvc/get.guest $VMID | grep -o -Ei -m 1 'ipaddress = "([^\"])*"' | awk -F "\"" '{print $2}')
        #VMIP=$(vim-cmd vmsvc/get.guest $VMID | grep -i -m 1 'ipaddress = "172.16.1' | awk -F "\"" '{print $2}')
        VMIP=$(vim-cmd vmsvc/get.guest $VMID | grep -i -m 1 'ipaddress = "'$IP_HEAD'' | awk -F "\"" '{print $2}')
        case $VMNAME in *) echo $VMID";"$VMNAME";"$VMIP;; esac
done

