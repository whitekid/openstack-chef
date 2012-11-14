bag = data_bag_item('openstack', 'default')

case node[:hostname]
when 'router-data'
	ip_forward = false
	nat_enable = false

	ifconfig '10.130.1.2' do
		device 'eth1'
		mask '255.255.255.0'
	end

when 'router-ext'
	ip_forward = true
	nat_enabled = false
	nat_iface = 'eth1'

	# default gw를 eth1으로 지정해서 외부로 traffic이 나가도록 설정
	# @note eth0에서 dhcp로 받으면 기본 gateway가 management network으로 나가게 된다.
	# 이를 틀어서 public network으로 나가도록 조정
	`route | grep ^default | awk '{print $2}'`.split.each do | gw | 
		execute "remove management default gw" do
			command "route del default gw #{gw}"
			only_if { gw != "10.100.1.1" }
		end
	end

	ifconfig bag['api_gw'] do
		device 'eth1'
		mask '255.255.255.0'
	end
	execute "add default gw to eth1" do
		command "route add default gw 10.100.1.1"
		not_if 'netstat -nr | grep ^0.0.0.0 | grep 10.100.1.1'
	end
end

execute "enable ip_foward" do
	command "sysctl net.ipv4.ip_forward=1"
	not_if "sysctl net.ipv4.ip_forward | grep ' = 1'"
	only_if { ip_forward }
end

execute "enable NAT" do
	command "iptables -t nat -A POSTROUTING -o #{nat_iface} -j MASQUERADE"
	not_if "iptables -t nat -L POSTROUTING -v | grep MASQUERADE | grep #{nat_iface}"
	only_if { nat_enabled }
end

# vim: nu ai ts=4 sw=4
