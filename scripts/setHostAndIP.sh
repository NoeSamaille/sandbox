#!/bin/sh

ME=${0##*/}
RED="\e[31m"
YELLOW="\e[33m"
LBLUE="\e[34m"
GREEN="\e[32m"
NC="\e[0m"

[ ! -z "$1" ] && NEW_HOSTNAME=$1 || { echo -e "$YELLOW USAGE: give short hostname as first parameter e.g. $ME host0. Exiting... $NC"; exit 1; }

DIG=$(command -v dig)

if [ -z "$DIG" ]; then
	echo -e "$RED !!! ERROR: dig not found in $PATH. Exiting... $NC"
	exit 1
fi

HOSTNAMECTL=$(command -v hostnamectl)

if [ -z "$HOSTNAMECTL" ]; then
	echo -e "$RED !!! ERROR: hostnamectl not found in $PATH. Exiting... $NC"
	exit 1
fi

DOMAIN="iicparis.fr.ibm.com"
DNS="172.16.160.100"
GATEWAY="172.16.186.17"
MASK="19"
IFCFG="/etc/sysconfig/network-scripts/ifcfg-ens192"
HOSTNAME=$(hostname -f | awk -F"." '{print $1}')

changeHostname (){

	if [ "$HOSTNAME" != "$NEW_HOSTNAME" ]; then

		hostnamectl set-hostname $NEW_HOSTNAME.$DOMAIN 
		[ $? -ne 0 ] && { echo -e "$RED !!! ERROR: changing hostname failed. Exiting..." $NC; exit 1; } ||echo -e "$GREEN Hostname changed to" $NEW_HOSTNAME.$DOMAIN $NC

	fi
}

clean (){
	sed -i '/^#.*$/d' $IFCFG
}

setDynamicIPAddr (){

	IS_BOOTPROTO=$(grep -cEi -m 1 '^bootproto=' $IFCFG)

	if [ "$IS_BOOTPROTO" -eq 1 ]; then
		sed -i 's/^bootproto.*$/BOOTPROTO="dhcp"/gI' $IFCFG
	else
		echo -e 'BOOTPROTO="dhcp"' >> $IFCFG
	fi

	sed -i 's/^\(ipaddr.*$\)/#\1/gI' $IFCFG
	sed -i 's/^\(prefix.*$\)/#\1/gI' $IFCFG
	sed -i 's/^\(gateway.*$\)/#\1/gI' $IFCFG
	sed -i 's/^\(dns1.*$\)/#\1/gI' $IFCFG
	sed -i 's/^\(domain.*$\)/#\1/gI' $IFCFG

	echo -e "$GREEN IP address set to dynamic" $NC

	echo -e "$LBLUE Restart network for changes to take effect. $NC"

}

setStaticIPAddr (){

	NEW_IPADDR=$(dig @$DNS $NEW_HOSTNAME.$DOMAIN +short)

	IS_BOOTPROTO=$(grep -cEi -m 1 '^bootproto=' $IFCFG)

	if [ "$IS_BOOTPROTO" -eq 1 ]; then
		sed -i 's/^bootproto.*$/BOOTPROTO="none"/gI' $IFCFG
	else
		echo -e 'BOOTPROTO="none"' >> $IFCFG
	fi

	IS_IPADDR=$(grep -cEi -m 1 '^ipaddr=' $IFCFG)

	if [ "$IS_IPADDR" -eq 1 ]; then
		sed -i 's/^ipaddr.*$/IPADDR="'$NEW_IPADDR'"/gI' $IFCFG
	else
		echo -e 'IPADDR="'$NEW_IPADDR'"' >> $IFCFG
	fi

	IS_PREFIX=$(grep -cEi -m 1 '^prefix=' $IFCFG)

	if [ "$IS_PREFIX" -eq 1 ]; then
		sed -i 's/^prefix.*$/PREFIX="'$MASK'"/gI' $IFCFG
	else
		echo -e 'PREFIX="'$MASK'"' >> $IFCFG
	fi

	IS_GATEWAY=$(grep -cEi -m 1 '^gateway=' $IFCFG)

	if [ "$IS_GATEWAY" -eq 1 ]; then
		sed -i 's/^gateway.*$/GATEWAY="'$GATEWAY'"/gI' $IFCFG
	else
		echo -e 'GATEWAY="'$GATEWAY'"' >> $IFCFG
	fi

	IS_DNS=$(grep -cEi -m 1 '^dns1=' $IFCFG)

	if [ "$IS_DNS" -eq 1 ]; then
		sed -i 's/^dns1.*$/DNS1="'$DNS'"/gI' $IFCFG
	else
		echo -e 'DNS1="'$DNS'"' >> $IFCFG
	fi

	IS_DOMAIN=$(grep -cEi -m 1 '^domain=' $IFCFG)

	if [ "$IS_DOMAIN" -eq 1 ]; then
		sed -i 's/^domain.*$/DOMAIN="'$DOMAIN'"/gI' $IFCFG
	else
		echo -e 'DOMAIN="'$DOMAIN'"' >> $IFCFG
	fi

	echo -e "$GREEN Static IP address set to" $NEW_IPADDR"/"$MASK $NC

	echo -e "$LBLUE Restart network for changes to take effect. $NC"

}

case $2 in

	host)
		changeHostname
		;;

	static)
		setStaticIPAddr
		;;

	dhcp)
		setDynamicIPAddr
		;;

	clean)
		clean
		;;

	*)
		changeHostname
		setStaticIPAddr
		;;

esac

exit 0
