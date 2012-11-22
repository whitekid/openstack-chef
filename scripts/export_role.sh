#!/bin/bash
for role in `knife role list`; do
	knife role show $role -Fj > roles/$role.json
done
# vim: nu ai ts=4 sw=4
