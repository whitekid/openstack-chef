class Chef::Recipe
	include Helper
end

bag = data_bag_item('openstack', 'default')

package "rabbitmq-server"

execute "rabbitmq" do
	command "rabbitmqctl change_password guest #{bag['rabbit_passwd']}"
end

# vim: nu ai ts=4 sw=4
