#
# Cookbook Name:: openstack
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
::Chef::Recipe.send(:include, Whitekid::Helper)

repo_node = get_roled_node('repo')

# 기본 패키지 사용
#use_package = :apt

# cloud archive 패키지 사용
use_package = :cloud_archive
cloud_archive_version = :folsom

case use_package
when :cloud_archive
	# cloud archive key package
	package "ubuntu-cloud-keyring"

	apt_repository "openstack-folsom" do
		#uri "http://ubuntu-cloud.archive.canonical.com/ubuntu #{node['lsb']['codename']}-updates/#{cloud_archive_version}"
		# @note cloud archive mirroring: see...
		uri "#{repo_node[:repo][:ubuntu][:cloud_archive]} #{node['lsb']['codename']}-updates/#{cloud_archive_version}"
		components ["main"]
	end
end


#
# utility scripts
#
directory "/root/bin" 
template "/root/bin/clear.sh" do
	mode "0700"
	source "clear.sh.erb"
end

keystone_host = get_roled_host('keystone-server')
template "/root/openrc" do
	source "openrc.erb"
	variables({
		"keystone_host" => keystone_host,
	})
end

# vim: nu ai ts=4 sw=4
