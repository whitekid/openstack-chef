name "quantum-l3-agent"
description ""
run_list(
    "role[quantum-agent]",
    "recipe[quantum::l3-agent]"
)
