::Chef::Recipe.send(:include, Whitekid::Helper)
::Chef::Recipe.send(:include, Openstack::Helper)
::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

include_recipe "openstack"

bag = data_bag_item('openstack', 'default')

db_node = get_roled_node('openstack-database')
control_host = get_roled_host('openstack-control')
rabbit_host = get_roled_host('openstack-rabbitmq')
keystone_node = get_roled_node('keystone-server')
repo_node = get_roled_node('repo')

# network setup for api-network
# @todo metadata ip는 api 서버에 연결된 public ip므로 자동으로 알 수 있을 것 같음
ifconfig bag['metadata_ip'] do
	device "eth1"
	mask "255.255.255.0"
end

route "172.16.0.0/16" do
	gateway bag["api_gw"]
end


# create tenants, user, service, endpoints
package "python-setuptools"
package "python-yaml"
template "/root/keystone-init.py" do
	mode "0755"
	source "control/keystone-init.py.erb"
end

template "/root/config.yaml" do
	mode "0644"
	source "control/config.yaml.erb"
	variables({
		"admin_token" => keystone_node['keystone']['admin_token'],
		"keystone_host" => keystone_node['ipaddress'],
		"control_host" => control_host,
		'keystone' => bag['keystone'],
	})
end

execute "keystone setup" do
	command "python /root/keystone-init.py /root/config.yaml"
	not_if "keystone --token=#{keystone_node['keystone']['admin_token']} --endpoint http://#{keystone_node['ipaddress']}:35357/v2.0 tenant-list | grep ' admin '"
end


#
# Glance
#
package "python-mysqldb"
%w{glance glance-api glance-common python-glanceclient glance-registry python-glance}.each do | pkg |
	package pkg do
		options "--force-yes"
	end
end

services(%w{glance-api glance-registry})

template "/etc/glance/glance-api-paste.ini" do
	mode "0644"
	owner "glance"
	group "glance"
	source "control/glance-api-paste.ini.erb"
	variables({
		"glance_passwd" => bag['keystone']['glance_passwd'],
	})

	notifies :restart, "service[glance-api]", :immediately
end


template "/etc/glance/glance-api.conf" do
	mode "0644"
	owner "glance"
	group "glance"
	source "control/glance-api.conf.erb"
	variables({
		"keystone_host" => keystone_node['ipaddress'],
		"glance_passwd" => bag['keystone']['glance_passwd'],
		"rabbit_host" => rabbit_host,
		"rabbit_passwd" => bag['rabbit_passwd'],
		"service_tenant_name" => "service",
		"service_user_name" => "glance",
		"service_user_passwd" => bag["keystone"]["glance_passwd"],
		"config_file" => "/etc/glance/glance-api-paste.ini",
		"flavor" => "keystone",
	})

	notifies :restart, "service[glance-api]", :immediately
end

connection = connection_string('glance', 'glance', db_node['mysql']['openstack_passwd']['glance'])
template "/etc/glance/glance-registry.conf" do
	mode "0644"
	owner "glance"
	group "glance"
	source "control/glance-registry.conf.erb"
	variables({
		"keystone_host" => keystone_node['ipaddress'],
		"glance_passwd" => bag['keystone']['glance_passwd'],
		"service_tenant_name" => "service",
		"service_user_name" => "glance",
		"service_user_passwd" => bag["keystone"]["glance_passwd"],
		"connection" => connection,
		"config_file" => "/etc/glance/glance-api-paste.ini",
		"flavor" => "keystone",
	})

	notifies :restart, "service[glance-registry]", :immediately
end

template "/etc/glance/glance-registry-paste.ini" do
	mode "0644"
	owner "glance"
	group "glance"
	source "control/glance-registry-paste.ini.erb"
	variables({
		"pipeline" => "authtoken context registryapp",
	})

	notifies :restart, "service[glance-registry]", :immediately
end

bash "glance db sync" do
	code <<-EOF
	glance-manage version_control 0
	glance-manage db_sync
	EOF
end

# @todo wget이 실패했을때 처리

base_url = "#{repo_node[:repo][:cloud_images][:url]}"
node[:openstack][:cloud_images].each do |image|
	bash "download cloud image: #{image[:name]}" do
		code <<-EOF
		export OS_TENANT_NAME=admin
		export OS_USERNAME=admin
		export OS_PASSWORD=#{bag['keystone']['admin_passwd']}
		export OS_AUTH_URL=http://#{keystone_node[:ipaddress]}:35357/v2.0 add
		glance image-create --name='#{image[:name]}' --disk-format=qcow2 --container-format=bare --is-public=true --location="#{base_url}/#{image[:url]}"
		EOF

		not_if "glance --os-tenant-name=admin --os-username=admin --os-password=#{bag['keystone']['admin_passwd']} --os-auth-url=http://#{keystone_node[:ipaddress]}:35357/v2.0 image-list | grep ' #{image[:name]} '"
	end
end


include_recipe "cinder"

#
# nova-services
#
package "python-nova" do
	only_if { node[:quantum][:apply_metadata_proxy_patch] }
end

# @todo apply patch will move to LWRP
python_dist_path = get_python_dist_path
execute "apply metadata proxy fetch" do
	action :nothing
	only_if { node[:quantum][:apply_metadata_proxy_patch] }
	subscribes :run, "package[python-nova]", :immediately
	command "wget -O - -q 'https://github.com/whitekid/nova/compare/stable/folsom...whitekid:metadata_proxy_p5' | patch -p1 -f || true"
	cwd "/usr/lib/python2.7/dist-packages"
end

packages(%w{nova-novncproxy novnc nova-api nova-ajax-console-proxy nova-cert nova-consoleauth nova-scheduler})
services(%w{nova-api nova-cert nova-consoleauth nova-novncproxy nova-scheduler})

connection = connection_string('nova', 'nova', db_node['mysql']['openstack_passwd']['nova'])

template "/etc/nova/nova.conf" do
	mode "0644"
	owner "nova"
	group "nova"
	source "control/nova.conf.erb"
	variables({
		"connection" => connection,
		"control_host" => control_host,
		"keystone_host" => keystone_node['ipaddress'],
		"service_tenant_name" => "service",
		"service_user_name" => "nova",
		"service_user_passwd" => bag["keystone"]["nova_passwd"],
		"rabbit_host" => rabbit_host,
		"rabbit_passwd" => bag['rabbit_passwd'],
		# quantum
		# @todo allow_overlapping_ip as quantum-api nodes attribute
		"network_api_class" => "nova.network.quantumv2.api.API",
		"quantum_tenant_name" => "service",
		"quantum_user_name" => "quantum",
		"quantum_user_passwd" => bag["keystone"]["quantum_passwd"],
		:apply_metadata_proxy_patch => node[:quantum][:apply_metadata_proxy_patch],

		# @note cinder를 사용하려면 nova-api에서 서비스하는 volume을 제거해야함
		"enabled_apis" => "ec2,osapi_compute,metadata",
	})

	notifies :run, "bash[nova db sync]", :immediately
	%w{nova-api nova-cert nova-consoleauth nova-novncproxy nova-scheduler}.each do |svc|
		notifies :restart, "service[#{svc}]", :immediately
	end
end

bash "nova db sync" do
	code <<-EOF
	nova-manage db sync
	EOF
end

template "/etc/nova/api-paste.ini" do
	mode "0644"
	owner "nova"
	group "nova"
	source "control/nova_api-paste.ini.erb"
	variables({
		"keystone_host" => keystone_node['ipaddress'],
		"service_tenant_name" => "service",
		"service_user_name" => "nova",
		"service_user_passwd" => bag["keystone"]["nova_passwd"],
	})

	%w{nova-api}.each do |svc|
		notifies :restart, "service[#{svc}]", :immediately
	end
end

execute "wait for nova-api service startup" do
	command "timeout 5 sh -c 'until wget http://#{control_host}:8774/ -O /dev/null -q; do sleep 1; done'"
end


#
# utility scripts
#
cookbook_file "/root/bin/vm_create.sh" do
	mode "0700"
	source "vm_create.sh"
end

cookbook_file "/root/bin/tenant_create.sh" do
	mode "0700"
	source "tenant_create.sh"
end

# vim: nu ai ts=4 sw=4
