class Chef::Recipe
	include Helper
end

bag = data_bag_item('openstack', 'default')

#
# cinder
#
# @todo /dev/loop0가 이미 사용 되었을 수도 있음..
packages(%w{tgt lvm2})

# backing file for volume
bash "create backing file" do
	code <<-EOF
	BACKING=/var/lib/cinder-volumes
	DEV=/dev/loop0

	truncate --size 100G $BACKING
	losetup $DEV $BACKING
	pvcreate $DEV
	vgcreate cinder-volumes $DEV
	EOF
	not_if "vgscan | grep cinder-volumes"
end

packages(%w{cinder-volume})
services(%w{cinder-volume})

# vim: nu ai ts=4 sw=4
