name "openstack-compute"
description ""
run_list(
    "role[openstack-base]",
    "role[quantum-agent]",
    "recipe[nova::common]",
    "recipe[nova::compute]"
)
