default[:keystone][:patches] = [
	# http://secstack.org/2012/11/cve-2012-5571-ec2-style-credentials-invalidation-issue/
	'https://github.com/openstack/keystone/commit/37308dd4f3e33f7bd0f71d83fd51734d1870713b.patch',
	# http://secstack.org/2012/11/cve-2012-5563/
	'https://github.com/openstack/keystone/commit/f9d4766249a72d8f88d75dcf1575b28dd3496681.patch',
	# http://secstack.org/2012/10/cve-2012-4457-token-authorization-for-a-user-in-a-disabled-tenant-is-allowed/
	'https://github.com/openstack/keystone/commit/4ebfdfaf23c6da8e3c182bf3ec2cb2b7132ef685.patch',
	# http://secstack.org/2012/10/cve-2012-4456-some-actions-in-keystone-admin-api-do-not-validate-token/
	'https://github.com/openstack/keystone/commit/868054992faa45d6f42d822bf1588cb88d7c9ccb.patch',
	'https://github.com/openstack/keystone/commit/1d146f5c32e58a73a677d308370f147a3271c2cb.patch',
	# http://secstack.org/2012/09/cve-2012-4413-revoking-a-role-does-not-affect-existing-tokens/
	'https://github.com/openstack/keystone/commit/efb6b3fca0ba0ad768b3e803a324043095d326e2.patch',
	# http://secstack.org/2012/09/cve-2012-3542-keystone-lack-of-authorization-for-adding-users-to-tenants/
	'https://github.com/openstack/keystone/commit/c13d0ba606f7b2bdc609a7f388334e5efec3f3aa.patch',
]

# vim: nu ai ts=4 sw=4
