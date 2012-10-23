#
# Cookbook Name:: openstack
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# @note 현재 패키지에는 folsom이 들어가 있다.
# 하지만 testing 패키지 말고는 완전히 테스트 되지 않았음
#
# 기본 패키지 사용
#use_package = :apt

# 테스팅 패키지 사용
use_package = :testing

# cloud archive 패키지 사용
# use_package = :cloud_archive
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

	# cloud archive repository
	# @note 이 레포지트리의 패키지는 설치할때 --force-yes 옵션이 필요하다.
	# 즉 아직 완전히 준비가 된 것 같지 않다.
	apt_repository "openstack-folsom" do
		uri "http://ubuntu-cloud.archive.canonical.com/ubuntu #{node['lsb']['codename']}-updates/#{cloud_archive_version}"
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

bag = data_bag_item('openstack', 'default')
template "/root/openrc" do
	source "openrc.erb"
	variables({
		"control_host" => bag['control_host'],
	})
end

# vim: nu ai ts=4 sw=4
