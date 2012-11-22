name "keystone-client"
description ""
run_list(
    "role[openstack-base]",
    "recipe[keystone::client]"
)
