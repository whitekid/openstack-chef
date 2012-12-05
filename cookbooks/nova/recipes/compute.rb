# nova-compute services
::Chef::Recipe.send(:include, Whitekid::Helper)
::Chef::Recipe.send(:include, Openstack::Helper)

rabbit_host = get_roled_host('openstack-rabbitmq')
control_host = get_roled_host('openstack-control')
db_node = get_roled_node('openstack-database')

node.override[:nova][:nova_conf_params][:compute_driver] = 'libvirt.LibvirtDriver'
node.override[:nova][:nova_conf_params][:libvirt_type] = :kvm
node.override[:nova][:nova_conf_params][:my_ip] = node[:ipaddress]
node.override[:nova][:nova_conf_params][:vncserver_listen] = node[:ipaddress]
node.override[:nova][:nova_conf_params][:vncserver_proxyclient_address] = node[:ipaddress]
node.override[:nova][:nova_conf_params][:glance_host] = control_host
node.override[:nova][:nova_conf_params][:s3_host] = control_host
node.override[:nova][:nova_conf_params][:cc_host] = control_host
node.override[:nova][:nova_conf_params][:ec2_host] = control_host

# quantum
node.override[:nova][:nova_conf_params][:libvirt_vif_driver] = 'nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver'

include_recipe('nova::common')

packages(%w{nova-compute openvswitch-switch quantum-plugin-openvswitch-agent})
services(%w{nova-compute}) do |s|
	s.subscribes :restart, 'template[nova_conf]'
end
services(%w{openvswitch-switch quantum-plugin-openvswitch-agent libvirt-bin})

# http://www.linux-kvm.org/page/VhostNet
execute 'enable vhost_net' do
	command "modprobe vhost_net"
	not_if "lsmod | grep vhost_net"
end

# ip address for storage
# @note storage의 address는 eth0 주소에서 2번째 network만 바꾼다. eg) 10.20.1.21 --> 10.130.1.21
ifconfig ipaddr_field_set(iface_addr(node, :eth0), 1, 140) do
	device 'eth2'
	mask '255.255.255.0'
end

# vim: nu ai ts=4 sw=4
