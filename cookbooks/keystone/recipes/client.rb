package "python-keystone"
package "python-keystoneclient"

# security paches
python_dist_path = get_python_dist_path

node[:keystone][:patches].each do | patch |
	execute "apply patch: #{patch}" do
		action :nothing
		command "wget -O - -q '#{patch}' | patch -p1"
		cwd python_dist_path
		subscribes :run, "package[python-keystone]", :immediately
	end
end

# vim: nu ai ts=4 sw=4
