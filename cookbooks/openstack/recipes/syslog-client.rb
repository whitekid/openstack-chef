::Chef::Recipe.send(:include, Whitekid::Helper)
# see http://www.sebastien-han.fr/blog/2012/12/05/openstack-and-rsyslog/

#
# syslog settings
log_host = node[:openstack][:use_syslog] ? get_roled_host('openstack-syslog') : nil

services %w{rsyslog}
template '/etc/rsyslog.d/stack.conf' do
	source 'rsyslog-client.conf.erb'
	variables({
		:log_host => log_host,
	})
	only_if { node[:openstack][:use_syslog] }
	notifies :restart, 'service[rsyslog]'
end

# vim: nu ai ts=4 sw=4
