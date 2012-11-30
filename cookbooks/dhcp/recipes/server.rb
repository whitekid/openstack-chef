package "isc-dhcp-server"

service "isc-dhcp-server" do
	supports :start => true, :stop => true, :restart => true, :status => true 
	action [:enable, :restart]
end

case node[:hostname]
when 'pxe'
	interfaces = 'eth0'
when 'router-data'
	interfaces = 'eth1'
else
	interfaces = ''
end

template "/etc/default/isc-dhcp-server" do
	source "default_isc-dhcp-server.erb"
	variables({
		:interfaces => interfaces,
	})
	notifies :restart, resources(:service => "isc-dhcp-server")
end

# @note pxe는 eth0에서 listen, 나머지는 eth1에서 listen
template "/etc/dhcp/dhcpd.conf" do
	source "dhcpd.conf.erb"
	mode 0644
	variables({
		:properties => data_bag_item('hosts', 'default')['properties'],
		:subnets => data_bag_item('hosts', 'default')['subnets'],
		:ipaddr => node['ipaddress'],
	})
	notifies :restart, resources(:service => "isc-dhcp-server")
end


# simple dns service
packages(%w"dnsmasq")
services(%w"dnsmasq")

template '/etc/dnsmasq.d/openstack.zone' do
	mode '0644'
	source 'dnsmasq.zone.erb'
	variables({
		:properties => data_bag_item('hosts', 'default')['properties'],
		:subnets => data_bag_item('hosts', 'default')['subnets'],
	})
	notifies :restart, 'service[dnsmasq]'
end


# vim: nu ai ts=4 sw=4
