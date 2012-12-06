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
		:admin_token => keystone_node[:keystone][:admin_token],
		:keystone_host => keystone_node[:fqdn],
		:control_host => control_host,
		:keystone => bag['keystone'],
	})
end

execute "keystone setup" do
	command "python /root/keystone-init.py /root/config.yaml"
	not_if "keystone --token=#{keystone_node[:keystone][:admin_token]} --endpoint http://#{keystone_node[:fqdn]}:35357/v2.0 tenant-list | grep ' admin '"
end


#
# Glance
#
package "python-mysqldb"
package "python-glance"

# security paches
python_dist_path = get_python_dist_path

node[:glance][:patches].each do | patch |
	execute "apply patche: #{patch}" do
		action :nothing
		command "wget -O - -q '#{patch}' | patch -p1"
		cwd python_dist_path
		subscribes :run, "package[python-glance]", :immediately
	end
end

packages(%w{glance glance-api glance-common python-glanceclient glance-registry python-glance})
services(%w{glance-api glance-registry})

template "/etc/glance/glance-api-paste.ini" do
	mode "0644"
	owner "glance"
	group "glance"
	source "control/glance-api-paste.ini.erb"
	variables({
		:glance_passwd => bag['keystone']['glance_passwd'],
	})

	notifies :restart, "service[glance-api]", :immediately
end


template "/etc/glance/glance-api.conf" do
	mode "0644"
	owner "glance"
	group "glance"
	source "control/glance-api.conf.erb"
	variables({
		:keystone_host => keystone_node[:fqdn],
		:glance_passwd => bag['keystone']['glance_passwd'],
		:rabbit_host => rabbit_host,
		:rabbit_passwd => bag['rabbit_passwd'],
		:service_tenant_name => :service,
		:service_user_name => :glance,
		:service_user_passwd => bag["keystone"]["glance_passwd"],
		:config_file => "/etc/glance/glance-api-paste.ini",
		:flavor => :keystone,
	})

	notifies :restart, "service[glance-api]", :immediately
end

connection = connection_string(:glance, :glance, db_node[:mysql][:openstack_passwd][:glance])
template "/etc/glance/glance-registry.conf" do
	mode "0644"
	owner "glance"
	group "glance"
	source "control/glance-registry.conf.erb"
	variables({
		:keystone_host => keystone_node[:fqdn],
		:glance_passwd => bag['keystone']['glance_passwd'],
		:service_tenant_name => :service,
		:service_user_name => :glance,
		:service_user_passwd => bag["keystone"]["glance_passwd"],
		:connection => connection,
		:config_file => "/etc/glance/glance-api-paste.ini",
		:flavor => :keystone,
	})

	notifies :restart, "service[glance-registry]", :immediately
end

template "/etc/glance/glance-registry-paste.ini" do
	mode "0644"
	owner "glance"
	group "glance"
	source "control/glance-registry-paste.ini.erb"
	variables({
		:pipeline => "authtoken context registryapp",
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
		export OS_AUTH_URL=http://#{keystone_node[:fqdn]}:35357/v2.0 add
		glance image-create --name='#{image[:name]}' --disk-format=qcow2 --container-format=bare --is-public=true --location="#{base_url}/#{image[:url]}"
		EOF

		not_if "glance --os-tenant-name=admin --os-username=admin --os-password=#{bag['keystone']['admin_passwd']} --os-auth-url=http://#{keystone_node[:fqdn]}:35357/v2.0 image-list | grep ' #{image[:name]} '"
	end
end


# all nova things are in nova recipe


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
