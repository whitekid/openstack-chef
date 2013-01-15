default['repo']['apt-mirror']['mirrors'] = {
	'http://apt.opscode.com' => [
		%w"deb-amd64 precise-0.10 main testing",
		%w"deb-amd64 quantal-0.10 main testing",
		%w"deb-i386  precise-0.10 main testing",
		%w"deb-i386  quantal-0.10 main testing",
	],
	'http://ubuntu-cloud.archive.canonical.com/ubuntu' => [
		%w"deb-amd64 precise-updates/folsom main",
		%w"deb-i386  precise-updates/folsom main",
		%w"deb-amd64 precise-proposed/folsom main",
		%w"deb-i386  precise-proposed/folsom main",
		%w"deb-amd64 precise-updates/grizzly main",
		%w"deb-i386  precise-updates/grizzly main",
		%w"deb-amd64 precise-proposed/grizzly main",
		%w"deb-i386  precise-proposed/grizzly main",
	],
	'http://ftp.daum.net/ubuntu/' => [
		%w"deb-amd64 precise           main multiverse universe restricted main/debian-installer",
		%w"deb-i386  precise           main multiverse universe restricted main/debian-installer",
		%w"deb-src   precise           main multiverse universe restricted",
		%w"deb-amd64 precise-updates   main multiverse universe restricted main/debian-installer",
		%w"deb-i386  precise-updates   main multiverse universe restricted main/debian-installer",
		%w"deb-src   precise-updates   main multiverse universe restricted",
		%w"deb-amd64 precise-security  main multiverse universe restricted main/debian-installer",
		%w"deb-i386  precise-security  main multiverse universe restricted main/debian-installer",
		%w"deb-src   precise-security  main multiverse universe restricted",
		%w"deb-amd64 precise-proposed  main multiverse universe restricted main/debian-installer",
		%w"deb-i386  precise-proposed  main multiverse universe restricted main/debian-installer",
		%w"deb-src   precise-proposed  main multiverse universe restricted",
		%w"deb-amd64 precise-backports main multiverse universe restricted main/debian-installer",
		%w"deb-i386  precise-backports main multiverse universe restricted main/debian-installer",
		%w"deb-src   precise-backports main multiverse universe restricted",

		%w"deb-amd64 quantal           main multiverse universe restricted main/debian-installer",
		%w"deb-i386  quantal           main multiverse universe restricted main/debian-installer",
		%w"deb-src   quantal           main multiverse universe restricted",
		%w"deb-amd64 quantal-updates   main multiverse universe restricted main/debian-installer",
		%w"deb-i386  quantal-updates   main multiverse universe restricted main/debian-installer",
		%w"deb-src   quantal-updates   main multiverse universe restricted",
		%w"deb-amd64 quantal-security  main multiverse universe restricted main/debian-installer",
		%w"deb-i386  quantal-security  main multiverse universe restricted main/debian-installer",
		%w"deb-src   quantal-security  main multiverse universe restricted",
		%w"deb-amd64 quantal-proposed  main multiverse universe restricted main/debian-installer",
		%w"deb-i386  quantal-proposed  main multiverse universe restricted main/debian-installer",
		%w"deb-src   quantal-proposed  main multiverse universe restricted",
		%w"deb-amd64 quantal-backports main multiverse universe restricted main/debian-installer",
		%w"deb-i386  quantal-backports main multiverse universe restricted main/debian-installer",
		%w"deb-src   quantal-backports main multiverse universe restricted",
	],
}

default['repo']['cloud_images']['cirros'] = {
	"0.3.0/+download/cirros-0.3.0-x86_64-disk.img" => {
		:md5sum => "50bdc35edb03a38d91b1b071afb20a3c",
	},
}

default['repo']['cloud_images']['uec'] = {
	'precise/release-20121218/ubuntu-12.04-server-cloudimg-amd64-disk1.img' => {
		:md5sum => '3f1ec03af4729be7476e2e2205742c68',
	},
	'quantal/release-20121218/ubuntu-12.10-server-cloudimg-amd64-disk1.img' => {
		:md5sum => 'd2009bc433fc0fbe65b8796ac411b8c8',
	},
}

# https://github.com/rackerjoe/oz-image-build
default['repo']['cloud_images']['rcb'] = {
	"centos60_x86_64.qcow2" => {
		:md5sum => "",
	},
}

# vim: nu ai ts=4 sw=4
