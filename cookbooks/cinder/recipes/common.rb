#
# Cookbook Name:: cinder
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

::Chef::Recipe.send(:include, Whitekid::Helper)
::Chef::Recipe.send(:include, Openstack::Helper)

# cinder default settings
packages(%w{cinder-common})

bag = data_bag_item('openstack', 'default')

db_node = get_roled_node('openstack-database')
control_host = get_roled_host('openstack-control')
rabbit_host = get_roled_host('openstack-rabbitmq')

# @todo cinder iscsi listen address settings
# iscsi_ip_address = 10.140.1.7
# and compute node add connected that network

connection = connection_string(:cinder, :cinder, db_node[:mysql][:openstack_passwd][:cinder])
template "/etc/cinder/cinder.conf" do
	mode "0644"
	owner 'cinder'
	group 'cinder'
	source "cinder.conf.erb"
	variables({
		:connection => connection,
		:control_host => control_host,
		:rabbit_host => rabbit_host,
		:rabbit_passwd => bag['rabbit_passwd'],
		:rabbit_userid => :guest,
		:use_syslog => node[:openstack][:use_syslog],
		:iscsi_ip_address => node[:cinder][:iscsi_ip_address],
	})
end

# @note cinder는 python-novacommon에 설치되는데, 이는 nova-common의 의존성에 의해서 설치된다.
package "python-mysqldb"
execute "cinder db sync" do
	command "cinder-manage db sync"
end

# vim: nu ai ts=4 sw=4
