name "swift-account"
description ""
run_list(
  "role[openstack-base]",
  "recipe[swift::account]"
)
