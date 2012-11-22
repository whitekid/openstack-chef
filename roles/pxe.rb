name "pxe"
description ""
run_list(
    "recipe[ubuntu]",
    "recipe[ntp]",
    "recipe[dhcp]",
    "recipe[tftp]",
    "recipe[pxe]"
)
