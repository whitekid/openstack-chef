name "nova-api"
description ""
run_list(
    "role[openstack-base]",
    "recipe[nova::api]"
)
