name "quantum-agent"
description ""
run_list(
    "role[openstack-base]",
    "recipe[quantum::common]",
    "recipe[quantum::agent]"
)
