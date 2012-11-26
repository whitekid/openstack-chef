name "horizon"
description ""
run_list(
  "role[openstack-base]",
  "recipe[horizon]"
)
