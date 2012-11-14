class Chef::Recipe
	include Helper
end

packages(%w{nova-compute openvswitch-switch quantum-plugin-openvswitch-agent})
services(%w{nova-compute openvswitch-switch quantum-plugin-openvswitch-agent libvirt-bin})

# http://www.linux-kvm.org/page/VhostNet
execute 'enable vhost_net' do
	command "modprobe vhost_net"
	not_if "lsmod | grep vhost_net"
end

bag = data_bag_item('openstack', 'default')
connection = connection_string('nova', 'nova', bag['dbpasswd']['nova'])
template "/etc/nova/nova.conf" do
	mode "0644"
	user "nova"
	owner "nova"
	source "compute/nova.conf.erb"
	variables({
		"compute_driver" => "libvirt.LibvirtDriver",
		"libvirt_type" => "kvm",
		"my_ip" => node["ipaddress"],
		"vncserver_listen" => node["ipaddress"],
		"vncserver_proxyclient_address" => node["ipaddress"],
		"connection" => connection,
		"rabbit_host" => bag['rabbit_host'],
		"rabbit_passwd" => bag['rabbit_passwd'],
		"control_host" => bag['control_host'],
		"service_tenant_name" => "service",
		"service_user_name" => "nova",
		"service_user_passwd" => bag["keystone"]["nova_passwd"],
		# quantum
		"network_api_class" => "nova.network.quantumv2.api.API",
		"quantum_tenant_name" => "service",
		"quantum_user_name" => "quantum",
		"quantum_user_passwd" => bag["keystone"]["quantum_passwd"],
		"libvirt_vif_driver" => "nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver",
	})
	notifies :restart, "service[nova-compute]"
end

# @todo cgroup_devel_acl 수정
#template "/etc/libvirt/qemu.conf" do
#	mode "0644"
#	source "compute/qemu.conf.erb"
#	notifies :restart, "service[libvirt-bin]"
#end

# @note 원래는 이렇게 dhcp로 가져와야 하겠지만, 아래 local_ip 설정하는 부분에서 아이피를 얻으려고 하면 문제가 발생한다
# 이미 부팅한 상황에서는 큰 문제가 없는데 처음 부팅하여 실행할 때 이상하게 가져오지 못한다.
# %x(cmd)로 실행하면 resource가 실행하기 전에 실행이 되어버려서 그런 것 같기도 하고... hmm
#execute "data nic bring up" do
#	command "dhclient eth1"
#	not_if "ifconfig eth1 | grep 'inet addr'"
#end

# setup bridge
execute "ovs-vsctl -- --may-exist add-br br-int"

connection = connection_string('quantum', 'quantum', bag['dbpasswd']['quantum'])
template "/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini" do
	mode "0644"
	owner "quantum"
	group "quantum"
	source "compute/ovs_quantum_plugin.ini.erb"
	variables({
		"connection" => connection,
		"enable_tunneling" => true,
		"tenant_network_type" => 'gre',
		"tunnel_id_ranges" => '1:1000',
		"local_ip" => %x(until ifconfig eth1 | grep 'inet addr' > /dev/null; do dhclient eth1 > /dev/null; sleep 1; done; ifconfig eth1 | grep 'inet addr' | cut -d : -f 2 | awk '{print $1}'),
	})
	notifies :restart, "service[quantum-plugin-openvswitch-agent]"
end

template "/etc/quantum/api-paste.ini" do
	mode "0644"
	owner "quantum"
	group "quantum"
	source "compute/quantum_api-paste.ini.erb"
	variables({
		"control_host" => bag['control_host'],
		"service_tenant_name" => 'service',
		"service_user_name" => 'quantum',
		"service_user_passwd" => bag['keystone']['quantum_passwd'],
	})
	notifies :restart, "service[quantum-plugin-openvswitch-agent]"
end

template "/etc/quantum/quantum.conf" do
	mode "0644"
	owner "quantum"
	group "quantum"
	source "compute/quantum.conf.erb"
	variables({
		"control_host" => bag['control_host'],
		"rabbit_host" => bag['rabbit_host'],
		"rabbit_passwd" => bag['rabbit_passwd'],
		"rabbit_userid" => 'guest',
	})
	notifies :restart, "service[quantum-plugin-openvswitch-agent]"
end
# vim: nu ai ts=4 sw=4
