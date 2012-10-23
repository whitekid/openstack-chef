#!/bin/bash
# @todo 부팅하면서 메타데이터 서버에 접속하는데 timeout나는 문제
# @todo cinder support
IMAGE=${IMAGE:-cirros-0.3.0-x86_64}

function get_id() {
	echo x
}

function get_field() {
	echo x
}

if [ -z "$OS_TENANT_NAME" ]; then
	echo "openstack environ variables is not set"
	echo "please run . ~/openrc tenant_name"
	exit
fi

TENANT_ID=$(keystone tenant-list | grep " $OS_TENANT_NAME " | awk '{print $2}')
PRINET="${OS_TENANT_NAME}"
EXTNET="ext_net"

if [ "$1" = '-h' ]; then
	echo "Usage: `basename $0` vmname"
	echo
	echo "	-c	clear all network items"
	echo "	-h	show this screen"
	exit
fi

if [ "$1" = "-c" ]; then
	nova list | head -n -1 | tail -n +4 | awk '{print $2}' | xargs -L1 nova delete
	quantum subnet-list | head -n -1 | tail -n +4 | awk '{print $2}' | xargs -L1 quantum subnet-delete
	quantum net-list | head -n -1 | tail -n +4 | awk '{print $2}' | xargs -L1 quantum net-delete
	quantum router-list | head -n -1 | tail -n +4 | awk '{print $2}' | xargs -L1 quantum router-delete
	exit
fi

VM=$1

#
# create external network - only by admin
#
if [ "$OS_USERNAME" = 'admin' ]; then
	EXTNET_ID=$(quantum net-list -- --tenant_id=$TENANT_ID --router:external=True | awk "/ $EXTNET / { print \$2 }")
	if [ -z "$EXTNET_ID" ]; then
		EXTNET_ID=$(quantum net-create $EXTNET --tenant_id=$TENANT_ID --router:external=True | grep ' id ' | awk '{print $4}')
	fi

	# create external subnet
	EXTSUBNET_ID=$(quantum net-show $EXTNET_ID | awk "/ subnets / { print \$4 }")
	if [ $EXTSUBNET_ID = "|" ]; then
		EXTSUBNET_ID=$(quantum subnet-create $EXTNET_ID "10.100.1.0/24" --tenant_id=$TENANT_ID --name=${EXTNET}_subnet --enable_dhcp=False | awk '/ id / {print $4}')
	fi
else
	EXTNET_ID=$(quantum net-list -- --router:external=True | awk "/ $EXTNET / { print \$2 }")
fi

#
# tenant internal network
#

# create private network
NET_ID=$(quantum net-list -- --tenant_id=$TENANT_ID --name=$PRINET | awk "/ $PRINET / { print \$2 }")
if [ -z "$NET_ID" ]; then
	NET_ID=$(quantum net-create $PRINET --tenant_id=$TENANT_ID | grep ' id ' | awk '{print $4}')
fi
echo "NET=$NET_ID"

# create private subnet
SUBNET_ID=$(quantum net-show $NET_ID | awk "/ subnets / { print \$4 }")
if [ $SUBNET_ID = "|" ]; then
	SUBNET_ID=$(quantum subnet-create $NET_ID "172.16.1.0/24" \
				--tenant_id=$TENANT_ID --name=${PRINET}_subnet \
				--dns_nameservers list=true 168.126.63.1 8.8.8.8 | \
				awk '/ id / {print $4}')
fi
echo "SUBNET=$SUBNET_ID"

# now internal network is working
# and connect to external network

# create router for connect to external network
ROUTER_NAME="router_${OS_USERNAME}_ext"
ROUTER_ID=$(quantum router-list -- --tenant_id=$TENANT_ID --name=$ROUTER_NAME | head -n -1 | tail -n +4 | awk '{print $2}')
if [ -z "$ROUTER_ID" ]; then
	ROUTER_ID=$(quantum router-create --tenant_id=$TENANT_ID $ROUTER_NAME | awk '/ id /{print $4}')
fi
echo "ROUTER=$ROUTER_ID"

quantum router-interface-add $ROUTER_ID $SUBNET_ID
quantum router-gateway-set $ROUTER_ID $EXTNET_ID

#
# generate keypair
# default keypair name is ${OS_TENANT_NAME}_key
#
KEYNAME="${OS_TENANT_NAME}_key"
if ! nova keypair-list | grep " ${KEYNAME} " > /dev/null ; then
	nova keypair-add ${KEYNAME} > ${OS_TENANT_NAME}.key
fi


#
# boot instance
#
if [ ! -z "$VM" ]; then
	IMAGE_ID=$(nova image-list | grep " $IMAGE " | head -n 1 | awk '{print $2}')
	echo "IMAGE=$IMAGE_ID"

	VM_ID=$(nova boot --image=$IMAGE_ID --flavor=1 --nic net-id=$NET_ID --key_name= ${KEYNAME} $VM | awk '/ id /{print $4}')
	echo "VM=$VM_ID"

	nova show $VM_ID
fi


# vim: nu ai aw ts=4 sw=4
