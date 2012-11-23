::Chef::Recipe.send(:include, Whitekid::Helper)

packages(%w{quantum-l3-agent})
services(%w{quantum-l3-agent})

keystone_host = get_roled_host('keystone-server')

# apply l3 agent bug fix patch
execute "apply fetch" do
	action :nothing

	command "wget -O /dev/stdout -q https://github.com/openstack/quantum/commit/84d60f5fd477237bd856b97b9970dd796b10647e.patch | patch -p1"
	cwd "/usr/lib/python2.7/dist-packages"

	subscribes :run, "package[quantum-l3-agent]", :immediately
end

bag = data_bag_item('openstack', 'default')

# setup interface
execute "external nic bring up" do
	command "ip link set up eth2"
	not_if "ip addr show eth2 | grep eth2 | grep UP"
end

# setup bridge
execute "ovs-vsctl -- --may-exist add-br br-ex"
execute "ovs-vsctl -- --may-exist add-port br-ex eth2"

template "/etc/quantum/l3_agent.ini" do
	mode "0644"
	owner "quantum"
	group "quantum"
	source "l3_agent.ini.erb"
	variables({
		"keystone_host" => keystone_host,
		"metadata_ip" => bag['metadata_ip'],
		"region" => 'RegionOne',
		"service_tenant_name" => 'service',
		"service_user_name" => 'quantum',
		"service_user_passwd" => bag['keystone']['quantum_passwd'],
		"use_namespaces" => node['openstack']['use_namespaces'],
	})
	notifies :restart, "service[quantum-l3-agent]"
end

# vim: nu ai ts=4 sw=4
