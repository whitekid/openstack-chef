#
# Cookbook Name:: ubuntu
# Recipe:: default
#
# Copyright 2008-2009, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
::Chef::Recipe.send(:include, Whitekid::Helper)

include_recipe "apt"

repo_node = get_roled_node('repo')

case node[:platform]
when "ubuntu"
	node.set[:ubuntu][:archive_url]  = "http://#{repo_node[:ipaddress]}/#{repo_node[:repo][:ubuntu][:pkg_path]}"
	node.set[:ubuntu][:security_url] = "http://#{repo_node[:ipaddress]}/#{repo_node[:repo][:ubuntu][:pkg_path]}"
end

template "/etc/apt/sources.list" do
  mode 0644
  variables :code_name => node[:lsb][:codename]
  notifies :run, resources(:execute => "apt-get update"), :immediately
  source "sources.list.erb"
end

template "/etc/profile.d/home_bin_path.sh" do
	mode "0644"
	source "home_bin_path.sh.erb"
end

template "/etc/vim/vimrc.local" do
	source "vimrc.local.erb"
	mode "0644"
end

# vim: nu ai ts=4 sw=4
