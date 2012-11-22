name "quantum-server"
description ""
run_list(
    "recipe[quantum]",
    "recipe[quantum::server]"
)
