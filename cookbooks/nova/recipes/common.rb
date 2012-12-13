# common nova.conf settings
::Chef::Recipe.send(:include, Whitekid::Helper)
::Chef::Recipe.send(:include, Openstack::Helper)

bag = data_bag_item('openstack', 'default')

db_node = get_roled_node('openstack-database')
keystone_node = get_roled_node('keystone-server')
rabbit_host = get_roled_host('openstack-rabbitmq')
# @todo nova 서비스 설치하기 전에 quantum service가 셋업되어 있어야하는 상황임
# 현재는 quantum-server role이 control과 같은 host를 가정하고 있기 때문에 문제가
# 없지만 나중에 분리된다면 고려해야할 사항이다.
quantum_host = get_roled_host('quantum-server')

package "python-nova" do
	only_if { node[:quantum][:apply_metadata_proxy_patch] }
end

# @todo apply patch will move to LWRP
python_dist_path = get_python_dist_path
execute "apply metadata proxy patch" do
	action :nothing
	only_if { node[:quantum][:apply_metadata_proxy_patch] }
	subscribes :run, 'package[python-nova]', :immediately
	command "wget -O - -q 'https://github.com/whitekid/nova/compare/stable/folsom...whitekid:metadata_proxy.patch' | patch -p1 -f || true"
	cwd python_dist_path
end

# security patches
execute "CVE-2012-5625 : Information Leak In Libvirt LVM-Backed" do
	action :nothing
	subscribes :run, 'package[python-nova]', :immediately
	command "wget -O - -q 'https://github.com/openstack/nova/commit/a99a802e008eed18e39fc1d98170edc495cbd354.patch' | patch -p1"
	cwd python_dist_path
end

package "nova-common"

connection = connection_string(:nova, :nova, db_node[:mysql][:openstack_passwd][:nova])

# @todo allow_overlapping_ip as quantum-api nodes attribute
node.override[:nova][:nova_conf_params][:apply_metadata_proxy_patch] = node[:quantum][:apply_metadata_proxy_patch]

# @note cinder를 사용하려면 nova-api에서 서비스하는 volume을 제거해야함
node.override[:nova][:nova_conf_params][:enabled_apis] = "ec2,osapi_compute,metadata"

# common nova.conf settings
node.override[:nova][:nova_conf_params][:connection] = connection
node.override[:nova][:nova_conf_params][:rabbit_host] = rabbit_host
node.override[:nova][:nova_conf_params][:rabbit_passwd] = bag['rabbit_passwd']
node.override[:nova][:nova_conf_params][:keystone_host] = keystone_node[:fqdn]
node.override[:nova][:nova_conf_params][:service_tenant_name] = :service
node.override[:nova][:nova_conf_params][:service_user_name] = :nova
node.override[:nova][:nova_conf_params][:service_user_passwd] = bag["keystone"]["nova_passwd"]
node.override[:nova][:nova_conf_params][:network_api_class] = "nova.network.quantumv2.api.API"
node.override[:nova][:nova_conf_params][:quantum_host] = quantum_host
node.override[:nova][:nova_conf_params][:quantum_tenant_name] = :service
node.override[:nova][:nova_conf_params][:quantum_user_name] = :quantum
node.override[:nova][:nova_conf_params][:quantum_user_passwd] = bag["keystone"]["quantum_passwd"]
node.override[:nova][:nova_conf_params][:use_syslog] = node[:openstack][:use_syslog]

template "nova_conf" do
	path "/etc/nova/nova.conf"
	mode "0644"
	owner "nova"
	group "nova"
	source "nova.conf.erb"
	variables(node[:nova][:nova_conf_params])

	notifies :run, "bash[nova db sync]", :immediately
	# @todo 이 파일이 변경되면 nova-* service가 restart 되어야하는데, 이 서비스들은
	# 다른 recipe에 정의되어 있다. 어떻게하면 될까?
end

# @todo 이것은 어디서 하면 좋을까? 매번 실행하는 것은 뭔가 불합리하지 않나?
bash "nova db sync" do
	action :nothing
	code <<-EOF
	nova-manage db sync
	EOF
end

# vim: nu ai ts=4 sw=4
