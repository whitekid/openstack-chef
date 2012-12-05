# all nova services except nova-compute, nova-api

include_recipe "nova::common"

packages(%w{nova-novncproxy novnc nova-ajax-console-proxy nova-cert nova-consoleauth nova-scheduler})
services(%w{nova-cert nova-consoleauth nova-novncproxy nova-scheduler}) do |s|
	s.subscribes :restart, 'template[nova_conf]'
end

# vim: nu ai ts=4 sw=4
