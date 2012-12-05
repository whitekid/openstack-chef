name "openstack-control"
description ""
run_list(
    "role[openstack-base]",
    "role[keystone-client]",
    "role[quantum-server]",
    "recipe[nova::common]",
    "recipe[nova::api]",
    "recipe[nova::services]",
    "recipe[openstack::control]",
    "role[cinder-api]",
    "role[cinder-scheduler]"
)
