#!/bin/bash
find roles -type f -name '*.rb' -exec knife role from file {} \;
# vim: nu ai ts=4 sw=4
