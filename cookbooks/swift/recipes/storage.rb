services %w"rsync"

# directory for swift
directory node[:swift][:object_path] do
	owner 'swift'
	group 'swift'
	recursive true
end

# enable rsync for swift
execute "enable rsync" do
	command "sed -i /etc/default/rsync -e 's/RSYNC_ENABLE=false/RSYNC_ENABLE=true/g'"
end

template '/etc/rsyncd.conf' do
	source 'rsyncd.conf.erb'
	variables({
		:object_path => node[:swift][:object_path],
	})
	notifies :restart, resources(:service => :rsync)
end

# vim: nu ai ts=4 sw=4
