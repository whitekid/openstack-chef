name "openstack-control"
description ""
run_list(
    "role[openstack-base]",
    "role[keystone-client]",
    "recipe[openstack::control]",
    "role[quantum-server]",
    "role[cinder-api]",
    "role[cinder-scheduler]"
)
