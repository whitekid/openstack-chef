#
# Cookbook Name:: cinder
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

class Chef::Recipe
	include Helper
end

# cinder default settings
packages(%w{cinder-common})

bag = data_bag_item('openstack', 'default')

control_host = get_roled_host('openstack_control')
rabbit_host = get_roled_host('openstack_rabbitmq')

connection = connection_string('cinder', 'cinder', bag['dbpasswd']['cinder'])
template "/etc/cinder/cinder.conf" do
	mode "0644"
	owner "cinder"
	group "cinder"
	source "cinder.conf.erb"
	variables({
		"connection" => connection,
		"control_host" => control_host,
		"rabbit_host" => rabbit_host,
		"rabbit_passwd" => bag['rabbit_passwd'],
		"rabbit_userid" => 'guest',
	})
end

# @note cinder는 python-novacommon에 설치되는데, 이는 nova-common의 의존성에 의해서 설치된다.
package "python-mysqldb"
execute "cinder db sync" do
	command "cinder-manage db sync"
end

# vim: nu ai ts=4 sw=4
