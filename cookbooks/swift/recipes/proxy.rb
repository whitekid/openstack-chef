::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
node.set_unless[:swift][:swift_hash_path_suffix] = secure_password

include_recipe "swift::common"

packages %w{swift-proxy memcached}
services %w{swift-proxy memcached}

template '/etc/swift/proxy-server.conf' do
	owner 'swift'
	group 'swift'
	source 'proxy-server.conf.erb'
	variables({
	})
	if File.exists?('/etc/swift/account.ring.gz') and File.exists?('/etc/swift/object.ring.gz') and File.exists?('/etc/swift/container.gz')
		notifies :restart, resources(:service => 'swift-proxy')
	end
end

# create self signed cert
#execute "create cert" do
#	command "openssl req -new -x509 -nodes -out cert.crt -keyout cert.key"
#	not_if { File.exist?("/etc/swift/cert.key") }
#end

rings = %w{account container object}
rings.each do |ring|
	execute "build ring #{ring}" do
		user 'swift'
		group 'swift'
		command "swift-ring-builder #{ring}.builder create 18 3 1"
		cwd '/etc/swift'
		not_if { File.exist?("/etc/swift/#{ring}.builder") }
	end
end

# add node entries
rings = %w{account container object}

rings.each do |ring|
	nodes, _, _ = Chef::Search::Query.new.search(:node, "roles:swift-#{ring}")

	port = {
		'account' => 6002,
		'container' => 6001,
		'object' => 6000,
	}[ring]

	nodes.each do |n|
		execute "setup storage node #{ring} #{n[:ipaddress]}" do
			user 'swift'
			group 'swift'
			command "swift-ring-builder #{ring}.builder add z1-#{n[:ipaddress]}:#{port}/data 100 "
			cwd '/etc/swift'
			not_if "swift-ring-builder /etc/swift/#{ring}.builder | grep '#{n[:ipaddress]}'"
		end
	end
end

rings.each do |ring|
	execute "rebalance #{ring}" do
		user 'swift'
		group 'swift'
		command "swift-ring-builder #{ring}.builder rebalance"
		cwd '/etc/swift'
		not_if "swift-ring-builder /etc/swift/#{ring}.builder | grep ' 0.00 balance'"
		if File.exists?('/etc/swift/account.ring.gz') and File.exists?('/etc/swift/object.ring.gz') and File.exists?('/etc/swift/container.gz')
			notifies :restart, resources(:service => 'swift-proxy')
		end
	end
end

# copy ring to storage node
# @note 이것도 해당 role이 있는 node만 필요로하는 것 아닐까?

# vim: nu ai ts=4 sw=4
