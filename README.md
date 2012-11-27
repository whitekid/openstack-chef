# Overview
OpenStack Chef cookbooks with

* Ubuntu 12.04
* folsom release(ubuntu cloud archive)
* Quantum with openvswitch, gre tunnel
  * Per-tenant Routers with Private Networks model
  * http://docs.openstack.org/trunk/openstack-network/admin/content/use_cases_tenant_router.html
* pxe boot
* ubuntu/ centos repository cookbook

# Separatly install openstack component
 * database(with rabbitmq-server)
 * keystone
 * controller: glance(api+registry), nova-services(api, vnc, cert, consoleauth, novncproxy, scheduler)
 * cinder-volume
 * horizon
 * 2 nova-compute node
 * quantum-l3-agent
 * quantum-dhcp-agent

## and addition component
 * chef-server
 * pxe boot
 * repository

# patch applied
 * https://review.openstack.org/#/c/14756/ Call iptables without absolute path
 * https://review.openstack.org/#/q/topic:bp/metadata-overlapping-networks,n,z metadata api agent when overlapping_ip