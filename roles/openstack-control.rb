name "openstack-control"
description ""
run_list(
    "role[openstack-base]",
    "role[keystone-client]",
    "recipe[openstack::control]",
    "role[quantum-server]",
    "recipe[cinder::cinder-api]",
    "recipe[cinder::cinder-scheduler]"
)
