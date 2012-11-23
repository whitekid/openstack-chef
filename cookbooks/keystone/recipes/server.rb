::Chef::Recipe.send(:include, Whitekid::Helper)
::Chef::Recipe.send(:include, Openstack::Helper)
::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

packages(%w{"keystone"})
services(%w{keystone})

node.set_unless['keystone']['admin_token'] = secure_password

db_node = get_roled_node('openstack-database')

connection = connection_string('keystone', 'keystone', db_node['mysql']['openstack_passwd']['keystone'])
template "/etc/keystone/keystone.conf" do
	mode "0644"
	source "keystone.conf.erb"
	variables({
		"connection" => connection,
		"admin_token" => node['keystone']['admin_token'],
	})

	# @note: 여기서 재시작하지 않으면 keystone-init에서 오류가 발생함
	notifies :restart, "service[keystone]", :immediately
end

package "python-mysqldb"
execute "keystone db sync" do
	command "keystone-manage db_sync"
end

# vim: nu ai ts=4 sw=4
