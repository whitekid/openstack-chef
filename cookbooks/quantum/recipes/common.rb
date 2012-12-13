::Chef::Recipe.send(:include, Whitekid::Helper)

package "python-quantum" do
	only_if { node[:quantum][:apply_metadata_proxy_patch] }
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
		:rabbit_host => rabbit_host,
		:rabbit_passwd => bag['rabbit_passwd'],
		:rabbit_userid => :guest,
		:use_syslog => node[:openstack][:use_syslog],
		:allow_overlapping_ips => node['quantum']['allow_overlapping_ips'],
		:apply_metadata_proxy_patch => node[:quantum][:apply_metadata_proxy_patch],
	})
end

# apply l3 agent bug fix patch
python_dist_path = get_python_dist_path

execute "apply l3-agent iptables with absolute path patch" do
	action :nothing
	subscribes :run, "package[python-quantum]"
	command "wget -O - -q https://github.com/openstack/quantum/commit/84d60f5fd477237bd856b97b9970dd796b10647e.patch | patch -p1"
	cwd python_dist_path
end

execute "apply metadata proxy patch" do
	action :nothing
	only_if { node[:quantum][:apply_metadata_proxy_patch] }
	subscribes :run, "package[python-quantum]", :immediately
	only_if { node[:quantum][:apply_metadata_proxy_patch] }
	command "wget -O - -q 'https://github.com/whitekid/quantum/compare/stable/folsom...whitekid:metadata_proxy.patch' | patch -p1 -f || true"
	cwd python_dist_path
end

# vim: nu ai ts=4 sw=4
