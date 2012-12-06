name "nova-api"
description ""
run_list(
    "role[openstack-base]",
    "recipe[nova::common]",
    "recipe[nova::api]"
)
