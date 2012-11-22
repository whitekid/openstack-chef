name "quantum-dhcp-agent"
description ""
run_list(
    "role[quantum-agent]",
    "recipe[quantum::dhcp-agent]"
)
