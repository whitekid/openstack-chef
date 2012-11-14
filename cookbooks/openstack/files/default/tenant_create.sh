#!/bin/bash
set -e

# get role id for tenant's user
ADMIN_ROLE_ID=$(keystone role-list | awk "/ admin / { print \$2} ")
MEMBER_ROLE_ID=$(keystone role-list | awk "/ Member / { print \$2} ")

# create tenant
TENANT_NAME=$1

if [ -z "$TENANT_NAME" ]; then
	echo "Usage: `basename $0` tenant_name"
	exit
fi

if [ $OS_TENANT_NAME != 'admin' ]; then
	echo "this script must run by admin tenant"
	exit
fi

# create tenant
TENANT_ID=$(keystone tenant-list | awk "/ $TENANT_NAME /{ print \$2}")
if [ -z "$TENANT_ID" ]; then
	TENANT_ID=$(keystone tenant-create --name=$TENANT_NAME | awk "/ id /{print \$4}")
fi
echo "TENANT_ID=$TENANT_ID"

function create_user() {
	USERNAME=$1
	TENANT_ID=$2
	ROLES=$3

	# create user
	user_id=$(keystone user-list | awk "/ $USERNAME /{ print \$2 }")
	if [ -z "$user_id" ]; then
		user_id=$(keystone user-create --name=$USERNAME --pass=${USERNAME}_passwd --tenant-id=$TENANT_ID | awk "/ id /{ print \$4}")
	fi
	echo "USERID=$user_id"

	# assign role
	for role in $ROLES; do
		if [ -z "$(keystone user-role-list --user-id=$user_id --tenant-id=$TENANT_ID | grep ${role})" ]; then
			keystone user-role-add --user-id=$user_id --tenant-id=$TENANT_ID --role-id=$role
		fi
	done
}

create_user ${TENANT_NAME} $TENANT_ID "$ADMIN_ROLE_ID $MEMBER_ROLE_ID"
create_user ${TENANT_NAME}_member $TENANT_ID "$MEMBER_ROLE_ID"

# vim: nu ai aw ts=4 sw=4
