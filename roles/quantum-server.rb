name "quantum-server"
description ""
run_list(
    "recipe[quantum::common]",
    "recipe[quantum::server]"
)
