name "quantum-agent"
description ""
run_list(
    "role[openstack-base]",
    "recipe[quantum]",
    "recipe[quantum::agent]"
)
