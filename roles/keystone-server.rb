name "keystone-server"
description ""
run_list(
    "role[openstack-base]",
    "recipe[keystone::server]"
)
