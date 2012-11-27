# Register Images only apply to qcow2 image
# http://docs.openstack.org/trunk/openstack-compute/install/apt/content/uploading-to-glance.html
# http://docs.openstack.org/trunk/openstack-compute/admin/content/starting-images.html
#
# Creating raw or QCOW2 images
# http://docs.openstack.org/trunk/openstack-compute/admin/content/manually-creating-qcow2-images.html
#
# @todo md5sum
# url is relative path from repo cloud-images
default[:openstack][:cloud_images] = [
	# CirrOS QCOW2 image
	# https://launchpad.net/cirros
	{
		:name => "cirros-0.3.0-x86_64",
		:url => "cirros/cirros-0.3.0-x86_64-disk.img",
		:checksum => "50bdc35edb03a38d91b1b071afb20a3c",
	},
	# Ubuntu 12.04 cloud image
	{
		:name => 'ubuntu-12.04-server-cloudimg-amd64',
		:url => "uec-images/precise/release-20121026.1/ubuntu-12.04-server-cloudimg-amd64-disk1.img",
		:checksum => "030a4451f5968ee26d3d75b7759e0d8c",
	},
	# Ubuntu 12.10 cloud image
	{
		:name => 'ubuntu-12.10-server-cloudimg-amd64',
		:url => "uec-images/quantal/release-20121017/ubuntu-12.10-server-cloudimg-amd64-disk1.img",
		:checksum => "ba66e7e4f7eb9967fe044c808e92700a",
	},
	# RCB centos
	{
		:name => 'RCB CentOS 6.0 X86_64',
		:url => "rcb/centos60_x86_64.qcow2",
		:checksum => "",
	},
]

# vim: nu ai ts=4 sw=4
