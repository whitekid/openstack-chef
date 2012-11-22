#!/bin/bash
set -e

target="/var/spool/mirror/cloud-images/uec-images"

# cirros
images+="https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img "
for image in $images; do
	dest="$target/cirros"
	echo mkdir -p $dest
	echo wget -c -o $dest/`basename $image` $image
done


# ubuntu cloud images
base="http://uec-images.ubuntu.com/releases"

images=""
images+="precise/release-20121026.1/ubuntu-12.04-server-cloudimg-amd64-disk1.img "
images+="quantal/release-20121017/ubuntu-12.10-server-cloudimg-amd64-disk1.img "

for image in $images; do
	src="$base/$image"
	dest="$target/$image"

	echo mkdir -p `dirname $dest`
	echo wget -c -o $dest $src 
done

# vim: nu ai ts=4 sw=4
