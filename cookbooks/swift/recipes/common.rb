::Chef::Recipe.send(:include, Whitekid::Helper)

packages %w{python-swift swift}

directory '/etc/swift' do
	owner 'swift'
	group 'swift'
end

swift_account_node = get_roled_node('swift-proxy')

template '/etc/swift/swift.conf' do
	owner 'swift'
	group 'swift'
	source 'swift.conf.erb'
	variables({
		:swift_hash_path_suffix => swift_account_node[:swift][:swift_hash_path_suffix],
	})
end

# vim: nu ai ts=4 sw=4
