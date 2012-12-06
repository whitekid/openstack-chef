# nova-api services

bag = data_bag_item('openstack', 'default')
keystone_node = get_roled_node('keystone-server')

# network setup for api-network
ifconfig bag['metadata_ip'] do
	device "eth1"
	mask "255.255.255.0"
	not_if { node[:quantum][:apply_metadata_proxy_patch] }
end

route "172.16.0.0/16" do
	gateway bag["api_gw"]
	not_if { node[:quantum][:apply_metadata_proxy_patch] }
end

packages %w{nova-api}
services %w{nova-api} do |s|
	s.subscribes :restart, 'template[nova_conf]'
end

template 'nova_api_paste_conf' do
	path "/etc/nova/api-paste.ini"
	mode "0644"
	owner 'nova'
	group 'nova'
	source "api-paste.ini.erb"
	variables({
		:keystone_host => keystone_node[:fqdn],
		:service_tenant_name => :service,
		:service_user_name => :nova,
		:service_user_passwd => bag["keystone"]["nova_passwd"],
	})
	notifies :restart, 'service[nova-api]', :immediately
end

# @note nova-api가 시작하고 서비스가 올라가는데 시간이 걸림
execute "wait for nova-api service startup" do
	command "timeout 5 sh -c 'until wget http://#{node[:fqdn]}:8774/ -O /dev/null -q; do sleep 1; done'"
end

# vim: nu ai ts=4 sw=4
