default[:keystone][:patches] = [
	# http://secstack.org/2012/11/cve-2012-5571-ec2-style-credentials-invalidation-issue/
	'https://github.com/openstack/keystone/commit/37308dd4f3e33f7bd0f71d83fd51734d1870713b.patch',
	# http://secstack.org/2012/11/cve-2012-5563/
	'https://github.com/openstack/keystone/commit/f9d4766249a72d8f88d75dcf1575b28dd3496681.patch',
]

# vim: nu ai ts=4 sw=4
