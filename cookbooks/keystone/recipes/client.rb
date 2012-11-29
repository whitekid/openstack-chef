package "python-keystone"
package "python-keystoneclient"

# security paches
python_dist_path = get_python_dist_path
execute "apply metadata proxy patch" do
	action :nothing
	subscribes :run, 'package[python-nova]'
	command "wget -O - -q 'https://github.com/openstack/keystone/commit/37308dd4f3e33f7bd0f71d83fd51734d1870713b.patch' | patch -p1"
	cwd python_dist_path
	subscribes :run, "package[python-keystone]", :immediately
end

# vim: nu ai ts=4 sw=4
