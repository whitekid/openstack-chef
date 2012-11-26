::Chef::Recipe.send(:include, Whitekid::Helper)

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
		:allow_overlapping_ips => node['quantum']['allow_overlapping_ips'],
		:apply_metadata_proxy_patch => node[:quantum][:apply_metadata_proxy_patch],
	})
end

# vim: nu ai ts=4 sw=4
