default['openstack'] = {
	# Quantum
	# @note allow_overlapping_ips가 문제 있어서 현재는 사용하지 않음
	#"allow_overlapping_ips" => 'True',
	"allow_overlapping_ips" => 'False',
	"use_namespaces" => 'True',
}

# vim: nu ai ts=4 sw=4
