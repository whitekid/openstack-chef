#
# Cookbook Name:: horizon
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
packages(%w{python-boto openstack-dashboard})
services(%w{apache2})

control_host = get_roled_host('openstack-control')
keystone_host = get_roled_host('keystone-server')

template "/etc/openstack-dashboard/local_settings.py" do
	mode "0644"
	source "local_settings.py.erb"
	variables({
		:openstack_host => control_host,
		:keystone_host => keystone_host,

		:cache_backend => 'memcached://127.0.0.1:11211',
		:swift_enabled => "False",
		:quantum_enabled => "True",
	})
	notifies :restart, "service[apache2]"
end

# vim: nu ai ts=4 sw=4
