#
# Cookbook Name:: quantum
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
class Chef::Recipe
	include Helper
end

packages(%w{openvswitch-switch quantum-plugin-openvswitch-agent})
services(%w{openvswitch-switch quantum-plugin-openvswitch-agent})

bag = data_bag_item('openstack', 'default')

#
# network connectivity
# eth1: data-networks with dhcp enabled
#

# setup interface
# @todo eth1의 address를 bridge로 설정해야하는데...
execute "data nic bring up" do
	command "dhclient eth1"
	not_if "ifconfig eth1 | grep 'inet addr'"
end

# setup ovs bridge
execute "ovs-vsctl -- --may-exist add-br br-int"

connection = connection_string('quantum', 'quantum', bag['dbpasswd']['quantum'])
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

template "/etc/quantum/api-paste.ini" do
	mode "0644"
	owner "quantum"
	group "quantum"
	source "api-paste.ini.erb"
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
	source "quantum.conf.erb"
	variables({
		"control_host" => bag['control_host'],
		"rabbit_host" => bag['rabbit_host'],
		"rabbit_passwd" => bag['rabbit_passwd'],
		"rabbit_userid" => 'guest',
		"allow_overlapping_ips" => node['openstack']['allow_overlapping_ips'],
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
