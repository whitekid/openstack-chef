#!/bin/bash
# create tenant
# this script called by admin
name=$1

if [ -z "$name" ]; then
	echo "Usage: `basename $0` tenant_name"
	exit
fi

tenant_id=$(keystone tenant-list | awk "/ $name /{print \$2}")
if [ -z "$tenant_id" ]; then
	tenant_id=$(keystone tenant-create --name=$name --enable=True | awk '/ id /{print $4}')
fi

admin_role=$(keystone role-list | awk '/ admin /{print $2}')
member_role=$(keystone role-list | awk '/ Member /{print $2}')

shift
for user in $name ${name}_member $@; do
	user_id=$(keystone user-list --tenant-id=$tenant_id | awk "/ $user / { print \$2}")
	if [ -z "$user_id" ]; then
		user_id=$(keystone user-create --tenant-id=$tenant_id --name=$user --pass=${user}_passwd --enable True | awk '/ id / { print $4 }')
	fi

	if [ "$user" = "$name" ]; then
		keystone user-role-add --tenant-id=$tenant_id --user-id=$user_id --role_id=$admin_role > /dev/null
	fi

	keystone user-role-add --tenant-id=$tenant_id --user-id=$user_id --role_id=$member_role > /dev/null
done


# vim: nu ai aw ts=4 sw=4
