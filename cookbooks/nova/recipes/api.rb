# nova-api services
include_recipe "nova::common"

packages %w{nova-api}
services %w{nova-api} do |s|
	s.subscribes :restart, 'template[nova_conf]'
end

bag = data_bag_item('openstack', 'default')
keystone_node = get_roled_node('keystone-server')

# network setup for api-network
# @todo metadata ip는 api 서버에 연결된 public ip므로 자동으로 알 수 있을 것 같음
ifconfig bag['metadata_ip'] do
	device "eth1"
	mask "255.255.255.0"
	not_if { node[:quantum][:apply_metadata_proxy_patch] }
end

route "172.16.0.0/16" do
	gateway bag["api_gw"]
	not_if { node[:quantum][:apply_metadata_proxy_patch] }
end


template "/etc/nova/api-paste.ini" do
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

	notifies :restart, "service[nova-api]", :immediately
end

execute "wait for nova-api service startup" do
	command "timeout 5 sh -c 'until wget http://#{node[:fqdn]}:8774/ -O /dev/null -q; do sleep 1; done'"
end

# vim: nu ai ts=4 sw=4
