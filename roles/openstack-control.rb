name "openstack-control"
description ""
run_list(
    "role[openstack-base]",
    "role[keystone-client]",
    "role[quantum-server]",
    "recipe[openstack::control]",
    "recipe[nova::services]",
    "role[cinder-api]",
    "role[cinder-scheduler]"
)
