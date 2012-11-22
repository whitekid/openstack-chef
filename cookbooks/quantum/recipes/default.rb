class Chef::Recipe
	include Helper
end

package "quantum-common"

bag = data_bag_item('openstack', 'default')
rabbit_host = get_roled_host('openstack-rabbitmq')

template "/etc/quantum/quantum.conf" do
	mode "0644"
	owner "quantum"
	group "quantum"
	source "quantum.conf.erb"
	variables({
		"rabbit_host" => rabbit_host,
		"rabbit_passwd" => bag['rabbit_passwd'],
		"rabbit_userid" => 'guest',
		"allow_overlapping_ips" => node['openstack']['allow_overlapping_ips'],
	})
end

# vim: nu ai ts=4 sw=4
