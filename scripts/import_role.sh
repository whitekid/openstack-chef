#!/bin/bash
knife role list | xargs -L1 -I% knife role delete % -y
find roles -type f -name '*.rb' -exec knife role from file {} \;
# vim: nu ai ts=4 sw=4
