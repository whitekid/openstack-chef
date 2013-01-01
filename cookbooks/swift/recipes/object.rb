include_recipe 'swift::common'
include_recipe 'swift::storage'

packages %w"swift-object"
services %w"swift-object swift-object-replicator swift-object-auditor"

# vim: nu ai ts=4 sw=4
