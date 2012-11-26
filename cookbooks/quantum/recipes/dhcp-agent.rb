packages(%w{quantum-dhcp-agent})
services(%w{quantum-dhcp-agent})

template "/etc/quantum/dhcp_agent.ini" do
	mode "0644"
	owner "quantum"
	group "quantum"
	source "dhcp_agent.ini.erb"
	variables({
		:use_namespaces => node[:quantum][:use_namespaces],
	})
	notifies :restart, "service[quantum-dhcp-agent]"
end

# vim: nu ai ts=4 sw=4
