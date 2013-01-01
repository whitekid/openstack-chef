::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

include_recipe 'swift::common'
include_recipe 'swift::storage'

packages %w{swift-account}
services %w{swift-account swift-account-replicator swift-account-auditor}

# vim: nu ai ts=4 sw=4
