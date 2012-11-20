#
# Quantum
#
packages(%w{quantum-server quantum-plugin-openvswitch})
services(%w{quantum-server})

bag = data_bag_item('openstack', 'default')
keysthone_host = get_roled_host('keystone-server')
db_node = get_roled_node('openstack-database')

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
		# @note control node not required local_ip settings
	})
	notifies :restart, "service[quantum-server]"
end

template "/etc/quantum/api-paste.ini" do
	mode "0644"
	owner "quantum"
	group "quantum"
	source "api-paste.ini.erb"
	variables({
		"keysthone_host" => keysthone_host,
		"service_tenant_name" => 'service',
		"service_user_name" => 'quantum',
		"service_user_passwd" => bag['keystone']['quantum_passwd'],
	})
	notifies :restart, "service[quantum-server]"
end

# vim: nu ai ts=4 sw=4
