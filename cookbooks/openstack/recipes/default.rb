#
# Cookbook Name:: openstack
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
class Chef::Recipe
	include Helper
end


# @note 현재 패키지에는 folsom이 들어가 있다.
# 하지만 testing 패키지 말고는 완전히 테스트 되지 않았음
#
# 기본 패키지 사용
#use_package = :apt

# 테스팅 패키지 사용
#use_package = :testing

# cloud archive 패키지 사용
use_package = :cloud_archive
cloud_archive_version = :folsom

case use_package
when :testing
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
when :cloud_archive
	# cloud archive key package
	package "ubuntu-cloud-keyring"

	apt_repository "openstack-folsom" do
		#uri "http://ubuntu-cloud.archive.canonical.com/ubuntu #{node['lsb']['codename']}-updates/#{cloud_archive_version}"
		# @note cloud archive mirroring: see...
		uri "http://192.168.100.108:8080/apt-mirror/ubuntu-cloud.archive.canonical.com/ubuntu #{node['lsb']['codename']}-updates/#{cloud_archive_version}"
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
