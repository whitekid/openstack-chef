name "openstack-syslog-server"
description ""
run_list(
    "role[openstack-base]",
    "recipe[openstack::syslog-server]"
)
