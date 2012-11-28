::Chef::Recipe.send(:include, Whitekid::Helper)

packages(%w{quantum-l3-agent})
services(%w{quantum-l3-agent})

# setup services quantum-metadata-agent services
template "/etc/init/quantum-metadata-agent.conf" do
	mode "0644"
	source "quantum-metadata-agent.conf.erb"
	only_if { node[:quantum][:apply_metadata_proxy_patch] }
end

link "/etc/init.d/quantum-metadata-agent" do
	to "/lib/init/upstart-job"
	only_if { node[:quantum][:apply_metadata_proxy_patch] }
end

services(%w{quantum-metadata-agent})

# copy executable scripts
%w{quantum-metadata-agent quantum-ns-metadata-proxy}.each do | script |
	execute "set executable #{script}" do
		command "chmod +x /usr/lib/python2.7/dist-packages/bin/#{script}"
	end

	link "/usr/local/bin/#{script}" do
		mode "0766"
		to "/usr/lib/python2.7/dist-packages/bin/#{script}"
		notifies :restart, "service[quantum-metadata-agent]"
	end
end

template "/etc/quantum/rootwrap.d/l3.filters" do
	source "l3.filters.erb"
	variables({
		:apply_metadata_proxy_patch => node[:quantum][:apply_metadata_proxy_patch],
	})
	notifies :restart, "service[quantum-l3-agent]"
end
# end overlappingip-metadata proxy

keystone_host = get_roled_host('keystone-server')

bag = data_bag_item('openstack', 'default')
#metadata_ip = iface_addr(get_roled_node('openstack-control'), 'eth1')
metadata_ip = bag['metadata_ip']

# setup interface
execute "external nic bring up" do
	command "ip link set up eth2"
	not_if "ip addr show eth2 | grep eth2 | grep UP"
end

# setup bridge
execute "ovs-vsctl -- --may-exist add-br br-ex"
execute "ovs-vsctl -- --may-exist add-port br-ex eth2"

metadata_port = '8775'
if node[:quantum][:apply_metadata_proxy_patch] then
	# @note 이런 구성이면 management network으로 가야한다.
	nova_metadata_ip = get_roled_host('openstack-control')
	metadata_ip = '127.0.0.1'
	metadata_port = '9697'
end

template "/etc/quantum/l3_agent.ini" do
	mode '0644'
	owner "quantum"
	group "quantum"
	source "l3_agent.ini.erb"
	variables({
		:keystone_host => keystone_host,
		:metadata_port => metadata_port,
		:region => :RegionOne,
		:service_tenant_name => :service,
		:service_user_name => :quantum,
		:service_user_passwd => bag['keystone']['quantum_passwd'],
		:use_namespaces => node[:quantum][:use_namespaces],
	})
	notifies :restart, "service[quantum-l3-agent]"
end

template "/etc/quantum/metadata_agent.ini" do
	only_if { node[:quantum][:apply_metadata_proxy_patch] }
	mode "0644"
	owner "quantum"
	group "quantum"
	source "metadata_agent.ini.erb"
	variables({
		:keystone_host => keystone_host,
		:nova_metadata_ip => nova_metadata_ip,
		:region => :RegionOne,
		:service_tenant_name => :service,
		:service_user_name => :quantum,
		:service_user_passwd => bag['keystone']['quantum_passwd'],
	})
	notifies :restart, "service[quantum-metadata-agent]"
end

# vim: nu ai ts=4 sw=4
