# nova-api services
packages %w{nova-api}
services %w{nova-api} do |s|
	s.subscribes :restart, 'template[nova_conf]'
end

bag = data_bag_item('openstack', 'default')
keystone_node = get_roled_node('keystone-server')

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
