name "cinder-scheduler"
description ""
run_list(
  "role[openstack-base]",
  "recipe[cinder::common]",
  "recipe[cinder::scheduler]"
)
