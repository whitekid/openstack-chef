name "cinder-volume"
description ""
run_list(
  "role[openstack-base]",
  "recipe[cinder]",
  "recipe[cinder::cinder-volume]"
)
