class Chef::Recipe
	include Helper
end

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

bag = data_bag_item('openstack', 'default')

#
# Databases
#
node.set_unless['mysql']['server_debian_password'] = secure_password
node.set_unless['mysql']['server_root_password']   = secure_password
node.set_unless['mysql']['server_repl_password']   = secure_password

include_recipe "mysql::server"

node.set_unless['mysql']['openstack_passwd'] = {}
%w{keystone glance nova cinder quantum}.each do | db |
	node.set_unless['mysql']['openstack_passwd'][db] = secure_password
	create_db(db, db, node['mysql']['openstack_passwd'][db])
end

# vim: nu ai ts=4 sw=4
