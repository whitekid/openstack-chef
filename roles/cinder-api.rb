name "cinder-api"
description ""
run_list(
  "role[openstack-base]",
  "recipe[cinder::common]",
  "recipe[cinder::api]"
)
