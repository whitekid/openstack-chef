name "swift-container"
description ""
run_list(
  "role[openstack-base]",
  "recipe[swift::container]"
)
