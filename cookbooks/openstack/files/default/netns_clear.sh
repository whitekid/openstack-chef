#!/bin/bash
# clear unused ip namespace
netns=''

for ns in `ip netns`; do
	if [ ${ns:0:7} = 'qrouter' ]; then
		router_id=${ns:8}

		quantum router-list -- --id=$router_id | grep " $router_id " > /dev/null || netns+="$ns "
	fi

	if [ ${ns:0:5} = 'qdhcp' ]; then
		net_id=${ns:6}

		quantum net-list -- --id=$net_id | grep " $net_id " > /dev/null || netns+="$ns "
	fi
done

echo "deleting $netns"
echo $netns | xargs -L1 ip netns delete

# vim: nu ai ts=4 sw=4
