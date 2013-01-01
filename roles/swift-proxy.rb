name "swift-proxy"
description ""
run_list(
  "role[openstack-base]",
  "recipe[swift::proxy]"
)
