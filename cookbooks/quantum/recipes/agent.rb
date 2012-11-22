class Chef::Recipe
	include Helper
end

packages(%w{openvswitch-switch quantum-plugin-openvswitch-agent})
services(%w{openvswitch-switch quantum-plugin-openvswitch-agent})

bag = data_bag_item('openstack', 'default')

db_node = get_roled_node('openstack-database')
rabbit_host = get_roled_host('openstack-rabbitmq')

#
# network connectivity
# eth1: data-networks with dhcp enabled
#
execute "data nic bring up" do
	command "dhclient eth1"
	not_if "ifconfig eth1 | grep 'inet addr'"
end

# setup bridge
execute "ovs-vsctl -- --may-exist add-br br-int"

connection = connection_string('quantum', 'quantum', db_node['mysql']['openstack_passwd']['quantum'])
template "/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini" do
	mode "0644"
	owner "quantum"
	group "quantum"
	source "ovs_quantum_plugin.ini.erb"
	variables({
		"connection" => connection,
		"enable_tunneling" => true,
		"tenant_network_type" => 'gre',
		"tunnel_id_ranges" => '1:1000',
		"local_ip" => node['eth1'],
		"local_ip" => %x(until ifconfig eth1 | grep 'inet addr' > /dev/null; do dhclient eth1 > /dev/null; sleep 1; done; ifconfig eth1 | grep 'inet addr' | cut -d : -f 2 | awk '{print $1}'),
	})
	notifies :restart, "service[quantum-plugin-openvswitch-agent]"
end

#
# utility scripts
#
cookbook_file "/root/bin/netns_clear.sh" do
	mode "0755"
	source "netns_clear.sh"
end

# vim: nu ai ts=4 sw=4
