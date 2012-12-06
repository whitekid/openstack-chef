name "openstack-base"
description ""
run_list(
    "recipe[ubuntu]",
    "recipe[ntp]",
    "recipe[apt]",
    "recipe[openstack]",
    "recipe[openstack::syslog-client]"
)
