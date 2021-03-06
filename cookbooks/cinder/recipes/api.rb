#
# Cookbook Name:: cinder
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

packages(%w{cinder-api})
services(%w{cinder-api})

bag = data_bag_item('openstack', 'default')
keystone_host = get_roled_host('keystone-server')

template "/etc/cinder/api-paste.ini" do
	mode "0644"
	owner 'cinder'
	group 'cinder'
	source "api-paste.ini.erb"
	variables({
		:keystone_host => keystone_host,
		:service_tenant_name => :service,
		:service_user_name => :cinder,
		:service_user_passwd => bag['keystone']['cinder_passwd'],
		:cinder_port => 6000,
	})
	notifies :restart, "service[cinder-api]"
end

# vim: nu ai ts=4 sw=4
