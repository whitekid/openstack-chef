class Chef::Recipe
	include Helper
end

packages(%w{openvswitch-switch quantum-dhcp-agent quantum-l3-agent quantum-plugin-openvswitch-agent})
services(%w{openvswitch-switch quantum-dhcp-agent quantum-l3-agent quantum-plugin-openvswitch-agent})

bag = data_bag_item('openstack', 'default')

# setup interface
# @todo eth1의 address를 bridge로 설정해야하는데...
execute "data nic bring up" do
	command "dhclient eth1"
	not_if "ifconfig eth1 | grep 'inet addr'"
end

execute "external nic bring up" do
	command "ip link set up eth2"
	not_if "ip addr show eth2 | grep eth2 | grep UP"
end

# setup bridge
execute "ovs-vsctl -- --may-exist add-br br-ex"
execute "ovs-vsctl -- --may-exist add-port br-ex eth2"
execute "ovs-vsctl -- --may-exist add-br br-int"


connection = connection_string('quantum', 'quantum', bag['dbpasswd']['quantum'])
template "/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini" do
	mode "0644"
	owner "quantum"
	group "quantum"
	source "network/ovs_quantum_plugin.ini.erb"
	variables({
		"connection" => connection,
		"enable_tunneling" => true,
		"tenant_network_type" => 'gre',
		"tunnel_id_ranges" => '1:1000',
		"local_ip" => node['eth1'],
		"local_ip" => %x(until ifconfig eth1 | grep 'inet addr' > /dev/null; do dhclient eth1 > /dev/null; sleep 1; done; ifconfig eth1 | grep 'inet addr' | cut -d : -f 2 | awk '{print $1}'),
	})
	notifies :restart, "service[quantum-dhcp-agent]"
	notifies :restart, "service[quantum-l3-agent]"
	notifies :restart, "service[quantum-plugin-openvswitch-agent]"
end

template "/etc/quantum/api-paste.ini" do
	mode "0644"
	owner "quantum"
	group "quantum"
	source "network/quantum_api-paste.ini.erb"
	variables({
		"control_host" => bag['control_host'],
		"service_tenant_name" => 'service',
		"service_user_name" => 'quantum',
		"service_user_passwd" => bag['keystone']['quantum_passwd'],
	})
	notifies :restart, "service[quantum-dhcp-agent]"
	notifies :restart, "service[quantum-l3-agent]"
	notifies :restart, "service[quantum-plugin-openvswitch-agent]"
end

template "/etc/quantum/quantum.conf" do
	mode "0644"
	owner "quantum"
	group "quantum"
	source "network/quantum.conf.erb"
	variables({
		"control_host" => bag['control_host'],
		"rabbit_passwd" => bag['rabbit_passwd'],
		"rabbit_userid" => 'guest',
	})
	notifies :restart, "service[quantum-dhcp-agent]"
	notifies :restart, "service[quantum-l3-agent]"
	notifies :restart, "service[quantum-plugin-openvswitch-agent]"
end

template "/etc/quantum/quantum.conf" do
	mode "0644"
	owner "quantum"
	group "quantum"
	source "network/quantum.conf.erb"
	variables({
		"control_host" => bag['control_host'],
		"rabbit_passwd" => bag['rabbit_passwd'],
		"rabbit_userid" => 'guest',
		"allow_overlapping_ips" => node['openstack']['allow_overlapping_ips'],
	})
	notifies :restart, "service[quantum-dhcp-agent]"
	notifies :restart, "service[quantum-l3-agent]"
	notifies :restart, "service[quantum-plugin-openvswitch-agent]"
end

template "/etc/quantum/l3_agent.ini" do
	mode "0644"
	owner "quantum"
	group "quantum"
	source "network/l3_agent.ini.erb"
	variables({
		"control_host" => bag['control_host'],
		"region" => 'RegionOne',
		"service_tenant_name" => 'service',
		"service_user_name" => 'quantum',
		"service_user_passwd" => bag['keystone']['quantum_passwd'],
		"use_namespaces" => node['openstack']['use_namespaces'],
	})
	notifies :restart, "service[quantum-l3-agent]"
end

template "/etc/quantum/dhcp_agent.ini" do
	mode "0644"
	owner "quantum"
	group "quantum"
	source "network/dhcp_agent.ini.erb"
	variables({
		"use_namespaces" => node['openstack']['use_namespaces'],
	})
	notifies :restart, "service[quantum-dhcp-agent]"
end

#
# utility scripts
#
cookbook_file "/root/bin/netns_clear.sh" do
	mode "0755"
	source "netns_clear.sh"
end

# vim: nu ai ts=4 sw=4
