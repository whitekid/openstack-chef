class Chef::Recipe
	include Helper
end

bag = data_bag_item('openstack', 'default')

control_host = get_roled_host('openstack_control')
rabbit_host = get_roled_host('openstack_rabbitmq')

# network setup for api-network
ifconfig bag['metadata_ip'] do
	device "eth1"
	mask "255.255.255.0"
end

route "172.16.0.0/16" do
	gateway bag["api_gw"]
end


#
# Keystone
#
packages(%w{"keystone"})
services(%w{keystone})

connection = connection_string('keystone', 'keystone', bag['dbpasswd']['keystone'])
template "/etc/keystone/keystone.conf" do
	mode "0644"
	source "control/keystone.conf.erb"
	variables({
		"connection" => connection,
		"admin_token" => bag['admin_token'],
	})

	# @note: 여기서 재시작하지 않으면 keystone-init에서 오류가 발생함
	notifies :restart, "service[keystone]", :immediately
end

package "python-mysqldb"
execute "keystone db sync" do
	command "keystone-manage db_sync"
end


# create tenants, user, service, endpoints
package "python-yaml"
template "/root/keystone-init.py" do
	mode "0755"
	source "control/keystone-init.py.erb"
end

template "/root/config.yaml" do
	mode "0644"
	source "control/config.yaml.erb"
	variables({
		"admin_token" => bag['admin_token'],
		"control_host" => control_host,
		'keystone' => bag['keystone'],
	})
end

execute "keystone setup" do
	command "python /root/keystone-init.py /root/config.yaml"
	not_if "keystone --token=#{bag['admin_token']} --endpoint http://#{control_host}:35357/v2.0 tenant-list | grep ' admin '"
end


#
# Glance
#
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
		"control_host" => control_host,
		"glance_passwd" => bag['keystone']['glance_passwd'],
		"rabbit_host" => rabbit_host,
		"rabbit_password" => bag['rabbit_passwd'],
		"service_tenant_name" => "service",
		"service_user_name" => "glance",
		"service_user_passwd" => bag["keystone"]["glance_passwd"],
		"config_file" => "/etc/glance/glance-api-paste.ini",
		"flavor" => "keystone",
	})

	notifies :restart, "service[glance-api]", :immediately
end

connection = connection_string('glance', 'glance', bag['dbpasswd']['glance'])
template "/etc/glance/glance-registry.conf" do
	mode "0644"
	owner "glance"
	group "glance"
	source "control/glance-registry.conf.erb"
	variables({
		"control_host" => control_host,
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

# Register Images only apply to qcow2 image
# http://docs.openstack.org/trunk/openstack-compute/install/apt/content/uploading-to-glance.html
# http://docs.openstack.org/trunk/openstack-compute/admin/content/starting-images.html
#
# Creating raw or QCOW2 images
# http://docs.openstack.org/trunk/openstack-compute/admin/content/manually-creating-qcow2-images.html
#
# @todo md5sum
images = [
	# CirrOS QCOW2 image
	# https://launchpad.net/cirros
	{
		"name" => "cirros-0.3.0-x86_64",
		"url" => "#{bag['cache_host']}/uec-images/cirros-0.3.0-x86_64-disk.img",
		"checksum" => "50bdc35edb03a38d91b1b071afb20a3c",
	},
	# Ubuntu 12.04 cloud image
	{
		"name" => 'ubuntu-12.04-server-cloudimg-amd64',
		#"url" => "http://uec-images.ubuntu.com/releases/precise/release-20121001/ubuntu-12.04-server-cloudimg-amd64-disk1.img",
		"url" => "#{bag['cache_host']}/uec-images/releases/precise/release-20121026.1/ubuntu-12.04-server-cloudimg-amd64-disk1.img",
		"checksum" => "030a4451f5968ee26d3d75b7759e0d8c",
	},
	# Ubuntu 12.10 cloud image
	{
		"name" => 'ubuntu-12.10-server-cloudimg-amd64',
		"url" => "#{bag['cache_host']}/uec-images/releases/quantal/release-20121017/ubuntu-12.10-server-cloudimg-amd64-disk1.img",
		"checksum" => "ba66e7e4f7eb9967fe044c808e92700a",
	},
]

# @todo wget이 실패했을때 처리
images.each do |image|
	bash "download cloud image: #{image['name']}" do
		local_file = "/var/cache/#{File.basename(image["url"])}"

		puts image['url']
		code <<-EOF
		wget -c -O #{local_file} #{image['url']}

		export OS_TENANT_NAME=admin
		export OS_USERNAME=admin
		export OS_PASSWORD=#{bag['keystone']['admin_passwd']}
		export OS_AUTH_URL=http://#{control_host}:35357/v2.0 add
		glance add name=#{image['name']} disk_format=qcow2 container_format=bare is_public=true < #{local_file}
		EOF

		not_if "glance --os-tenant-name=admin --os-username=admin --os-password=#{bag['keystone']['admin_passwd']} --os-auth-url=http://#{control_host}:35357/v2.0 image-list | grep ' #{image['name']} '"
	end
end


include_recipe "cinder"

#
# nova-services
#
# @todo nova-compute의 경우는 mysql에 접속하지 못하면 바로 에러를 내고 종료해버린다. 따라서 이 부분이 상당히 압에서 진행해야할 거 같다.
packages(%w{nova-novncproxy novnc nova-api nova-ajax-console-proxy nova-cert nova-consoleauth nova-scheduler})
services(%w{nova-api nova-cert nova-consoleauth nova-novncproxy nova-scheduler})

connection = connection_string('nova', 'nova', bag['dbpasswd']['nova'])

template "/etc/nova/nova.conf" do
	mode "0644"
	owner "nova"
	group "nova"
	source "control/nova.conf.erb"
	variables({
		"connection" => connection,
		"control_host" => control_host,
		"service_tenant_name" => "service",
		"service_user_name" => "nova",
		"service_user_passwd" => bag["keystone"]["nova_passwd"],
		"rabbit_host" => rabbit_host,
		"rabbit_password" => bag['rabbit_passwd'],
		# quantum
		"network_api_class" => "nova.network.quantumv2.api.API",
		"quantum_tenant_name" => "service",
		"quantum_user_name" => "quantum",
		"quantum_user_passwd" => bag["keystone"]["quantum_passwd"],

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
		"control_host" => control_host,
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
# Dashboard
#
packages(%w{openstack-dashboard})
services(%w{apache2})

template "/etc/openstack-dashboard/local_settings.py" do
	mode "0644"
	source "control/dashboard_local_settings.py.erb"
	variables({
		"cache_backend" => 'memcached://127.0.0.1:11211',
		"swift_enabled" => "False",
		"quantum_enabled" => "True",
	})
	notifies :restart, "service[apache2]"
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

template "/root/bin/keystone_clear.sh" do
	mode "0700"
	source "control/keystone_clear.sh.erb"

	variables({
		"mysql_passwd" => bag['dbpasswd']['mysql'],
	})
end
# vim: nu ai ts=4 sw=4
