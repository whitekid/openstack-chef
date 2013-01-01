include_recipe 'swift::common'
include_recipe 'swift::storage'

packages %w{swift-container}
services %w{swift-container swift-container-replicator swift-container-updater swift-container-auditor}

# vim: nu ai ts=4 sw=4
