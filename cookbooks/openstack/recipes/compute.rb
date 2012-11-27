::Chef::Recipe.send(:include, Whitekid::Helper)
::Chef::Recipe.send(:include, Openstack::Helper)

packages(%w{nova-compute openvswitch-switch quantum-plugin-openvswitch-agent})
services(%w{nova-compute openvswitch-switch quantum-plugin-openvswitch-agent libvirt-bin})

rabbit_host = get_roled_host('openstack-rabbitmq')
control_host = get_roled_host('openstack-control')
db_node = get_roled_node('openstack-database')

# http://www.linux-kvm.org/page/VhostNet
execute 'enable vhost_net' do
	command "modprobe vhost_net"
	not_if "lsmod | grep vhost_net"
end

bag = data_bag_item('openstack', 'default')
keystone_host = get_roled_host('keystone-server')
connection = connection_string('nova', 'nova', db_node['mysql']['openstack_passwd']['nova'])
template "/etc/nova/nova.conf" do
	mode "0644"
	user "nova"
	owner "nova"
	source "compute/nova.conf.erb"
	variables({
		:compute_driver => 'libvirt.LibvirtDriver',
		:libvirt_type => :kvm,
		:my_ip => node[:ipaddress],
		:vncserver_listen => node[:ipaddress],
		:vncserver_proxyclient_address => node[:ipaddress],
		:connection => connection,
		:rabbit_host => rabbit_host,
		:rabbit_passwd => bag['rabbit_passwd'],
		:control_host => control_host,
		:keystone_host => keystone_host,
		:service_tenant_name => :service,
		:service_user_name => :nova,
		:service_user_passwd => bag["keystone"]["nova_passwd"],
		# quantum
		:network_api_class => 'nova.network.quantumv2.api.API',
		:quantum_tenant_name => :service,
		:quantum_user_name => :quantum,
		:quantum_user_passwd => bag["keystone"]["quantum_passwd"],
		:libvirt_vif_driver => 'nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver',
	})
	notifies :restart, "service[nova-compute]"
end

# @todo cgroup_devel_acl 수정
#template "/etc/libvirt/qemu.conf" do
#	mode "0644"
#	source "compute/qemu.conf.erb"
#	notifies :restart, "service[libvirt-bin]"
#end

# vim: nu ai ts=4 sw=4
