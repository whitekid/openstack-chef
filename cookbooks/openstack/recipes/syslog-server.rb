# see http://www.sebastien-han.fr/blog/2012/12/05/openstack-and-rsyslog/
::Chef::Recipe.send(:include, Whitekid::Helper)

package "rsyslog"
services %w{rsyslog}

template "/etc/rsyslog.conf" do
	source "rsyslog.conf.erb"
	notifies :restart, 'service[rsyslog]'
end

directory node[:syslog][:log_path]

nodes, _, _ = Chef::Search::Query.new.search(:node, 'name:*')
template "/etc/rsyslog.d/stack.conf" do
	source "rsyslog-stack.conf.erb"
	variables({
		:log_path => node[:syslog][:log_path],
		:nodes => nodes,
	})
	notifies :restart, 'service[rsyslog]'
end

# @todo log_rotate

# vim: nu ai ts=4 sw=4
