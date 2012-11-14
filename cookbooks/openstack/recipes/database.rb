class Chef::Recipe
	include Helper
end

bag = data_bag_item('openstack', 'default')

#
# Databases
#
node.set['mysql']['server_debian_password'] = bag['dbpasswd']['mysql']
node.set['mysql']['server_root_password']   = bag['dbpasswd']['mysql']
node.set['mysql']['server_repl_password']   = bag['dbpasswd']['mysql']

include_recipe "mysql::server"

%w{keystone glance nova cinder quantum}.each do | db |
	create_db(db, db, bag['dbpasswd'][db])
end

# vim: nu ai ts=4 sw=4
