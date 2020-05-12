#!/bin/sh
DISK=/dev/sdb
PART=/dev/sdb1
VG=root
LV=root

which vim-cmd > /dev/null 2>&1

if [ $? -eq 0 ]; then
	echo "ERROR !!! vim-cmd found"
	echo "Script has to be executed on virtual machine. Exiting..."
	exit 1
fi

echo "- - -" > /sys/class/scsi_host/host0/scan

ls $PART > /dev/null

if [ $? -eq 0 ]; then
	echo "ERROR !!! Partition $PART already exists. Exiting..."
	exit 1
fi

(
echo n
echo p
echo 1
echo
echo
echo w
) | fdisk $DISK

sleep 5

ls $PART > /dev/null

if [ $? -ne 0 ]; then
	echo "ERROR !!! Partition $PART not found. Exiting..."
	exit 1
fi

vgdisplay $VG > /dev/null

if [ $? -ne 0 ]; then
	echo "ERROR !!! Volume group $VG not found. Exiting..."
	exit 1
fi

vgextend $VG $PART

EXT=$(pvdisplay $PART | awk '/Free PE/ {print $3}')

lvextend /dev/$VG/$LV -l +$EXT -r $PART

df -h /dev/$VG/$LV

exit  0
