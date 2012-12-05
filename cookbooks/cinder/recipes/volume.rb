::Chef::Recipe.send(:include, Whitekid::Helper)

bag = data_bag_item('openstack', 'default')

# ip address for iscsi
# @note storage의 address는 eth0 주소에서 2번째 network만 바꾼다. eg) 10.20.1.21 --> 10.130.1.21
eth1 = ipaddr_field_set(iface_addr(node, :eth0), 1, 140)
ifconfig eth1 do
	device 'eth1'
	mask '255.255.255.0'
end

node.set[:cinder][:iscsi_ip_address] = eth1
include_recipe "cinder::common"


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
