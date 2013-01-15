#
# Cookbook Name:: repo
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "nginx"

spool_dir = "/var/spool"
mirror_dir = "#{spool_dir}/mirror"
www_dir = "/var/www"
mirror_d = "/root/bin/mirror.d"

# Ubuntu package mirror using apt-mirror
package "apt-mirror"

template "/etc/apt/mirror.list" do
	mode "0644"
	source "mirror.list.erb"
	variables({
		'mirrors' => node['repo']['apt-mirror']['mirrors'],
	})
end

template "/etc/cron.d/apt-mirror" do
	source "apt-mirror.cron.erb"
end

link "#{www_dir}/apt-mirror" do
	to "#{spool_dir}/apt-mirror/mirror"
end

directory mirror_d do
	recursive true
end

node.override['repo']['ubuntu']['pkg_mirror_base'] = "http://#{node['fqdn']}/apt-mirror"
node.override['repo']['ubuntu']['pkg_path'] = "/mirror/ubuntu"
node.override['repo']['ubuntu']['cloud_archive'] = "#{node['repo']['ubuntu']['pkg_mirror_base']}/ubuntu-cloud.archive.canonical.com/ubuntu"
node.override['repo']['ubuntu']['chef'] = "#{node['repo']['ubuntu']['pkg_mirror_base']}/apt.opscode.com"

# Ubuntu archive mirror
# @todo add ubuarchive to crontab
package 'rsync'

dest = "#{mirror_dir}/ubuntu"
directory dest do
	recursive true
end

template "#{mirror_d}/mirror-ubuntu.sh" do
	mode '0755'
	source 'mirror-ubuntu.sh.erb'
	variables({
		:src => 'kr.archive.ubuntu.com::ubuntu',
		:dest => dest,
	})
end

# 이전 호환성을 위해서 link
link '/var/spool/apt-mirror/mirror/ftp.daum.net' do
	to dest
end

directory "#{www_dir}/mirror"
directory "#{mirror_dir}/ubuntu"

link "#{www_dir}/mirror/ubuntu" do
	to "#{mirror_dir}/ubuntu"
end

node.override['repo']['ubuntu']['pxe_linux_path'] = "/mirror/ubuntu"

# ubuntu-cd mirror
dest = "#{mirror_dir}/ubuntu-cd"
directory dest do
	recursive true
end

template "#{mirror_d}/mirror-ubuntu-cd.sh" do
	mode '0755'
	source 'mirror-ubuntu-cd.sh.erb'
	variables({
		:src => 'kr.archive.ubuntu.com::ubuntu-cd',
		:dest => dest,
	})
end

link "#{www_dir}/mirror/ubuntu-cd" do
	to "#{mirror_dir}/ubuntu-cd"
end

# CentOS 
dest = "#{mirror_dir}/CentOS"
directory dest
template "#{mirror_d}/mirror-centos.sh" do
	source "mirror-centos.sh.erb"
	mode "0755"
	variables({
		"src" => "ftp.kaist.ac.kr::centos",
		"dest" => dest,
	})
end
node.override['repo']['centos']['url'] = "http://#{node['fqdn']}/mirror/CentOS"

link "#{www_dir}/mirror/CentOS" do
	to "#{mirror_dir}/CentOS"
end

# cloud images
template "#{mirror_d}/mirror-cloud-images.sh" do
	source "mirror-cloud-images.sh.erb"
	mode "0755"
	variables({
		"mirror_dir" => mirror_dir,
		"cirros" => node['repo']['cloud_images']['cirros'],
		"uec" => node['repo']['cloud_images']['uec'],
		"rcb" => node['repo']['cloud_images']['rcb'],
	})
end

link "#{www_dir}/mirror/cloud-images" do
	to "#{mirror_dir}/cloud-images"
end

node.override[:repo][:cloud_images][:url] = "http://#{node[:fqdn]}/mirror/cloud-images"


# crontab
template "/root/bin/mirror.sh" do
	source "mirror.sh.erb"
	mode "0755"
end

cron "mirroring centos" do
	hour "3,9,15,18"
	minute 0
	command "/root/bin/mirror.sh"
end

# vim: nu ai ts=4 sw=4
