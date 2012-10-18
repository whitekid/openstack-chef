#
# Cookbook Name:: openstack
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

apt_repository "openstack-folsom-trunk-testing" do
	uri "http://ppa.launchpad.net/openstack-ubuntu-testing/folsom-trunk-testing/ubuntu #{node['lsb']['codename']}"
	components ["main"]
	keyserver "keyserver.ubuntu.com"
	key "3B6F61A6"
end

apt_repository "openstack-folsom-dep-staging" do
	uri "http://ppa.launchpad.net/openstack-ubuntu-testing/folsom-deps-staging/ubuntu #{node['lsb']['codename']}"
	components ["main"]
	keyserver "keyserver.ubuntu.com"
	key "3B6F61A6"
end

# cloud archive repository
#apt_repository "openstack-folsom" do
#	uri "http://ubuntu-cloud.archive.canonical.com/ubuntu #{node['lsb']['codename']}-updates/folsom"
#	components ["main"]
#end
#
## cloud archive key package
#package "ubuntu-cloud-keyring"


directory "/root/bin" 
template "/root/bin/clear.sh" do
	mode "0700"
	source "clear.sh.erb"
end

bag = data_bag_item('openstack', 'default')
template "/root/openrc" do
	source "openrc.erb"
	variables({
		"control_host" => bag['control_host'],
	})
end

# vim: nu ai ts=4 sw=4
