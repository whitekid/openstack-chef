bag = data_bag_item('openstack', 'default')

template '/etc/apt/apt.conf.d/proxy.conf' do
	source "proxy.conf.erb"
	variables({
		'proxy' => bag['proxy'],
	})
end

# vim: nu ai ts=4 sw=4
