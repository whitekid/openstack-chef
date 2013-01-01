name "swift-object"
description ""
run_list(
  "role[openstack-base]",
  "recipe[swift::object]"
)
