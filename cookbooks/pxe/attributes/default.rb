pkg_mirror =  {
	'ubuntu' => "192.168.13.3",
	'centos' => "192.168.13.3",
}
pkg_mirror['ubuntu'] = 'ftp.daum.net'

default['pxe']['common'] = {
	"packages" => "ntp
openssh-server
vim",
	"post_script" => "ntpdate -b -u pool.kr.ntp.org
hwclock -w
wget -O /etc/dhcp/dhclient-enter-hooks.d/set_hostname http://#{node[:ipaddress]}/files/set_hostname.ubuntu.sh
#perl -p -i -e 's/^(deb(-src){0,1}) (http[\:\/\d\.a-z-]+)/\1 http:\/\/#{node[:ipaddress]}untu/g' /etc/apt/sources.list
perl -p -i -e 's/^(deb(-src){0,1}) (http[\\:\\/\\d\\.a-z-]+)/\\1 http:\\/\\/#{pkg_mirror['ubuntu']}\\/ubuntu/g' /etc/apt/sources.list
"
}

mirrors = {
	'ubuntu' => "http://192.168.100.108:8080/ubuntu-releases",
	'centos' => "http://192.168.100.108:8080/centos",
}

default['pxe']['items'] = [
	{
		"id" => "ubuntu-12.04-amd64",
		"platform" => "ubuntu",
		"arch" => "amd64",
		"cdimage" => "#{mirrors['ubuntu']}/12.04/ubuntu-12.04.1-server-amd64.iso",
		'md5sum' => 'a8c667e871f48f3a662f3fbf1c3ddb17',
		"packages" => default['pxe']['common'][:packages],
		"post_script" => default['pxe']['common']["post_script"],
	},
	{
		"id" => "ubuntu-12.10-beta2-amd64",
		"platform" => "ubuntu",
		"arch" => "amd64",
		"cdimage" => "#{mirrors['ubuntu']}/12.10/ubuntu-12.10-beta2-server-amd64.iso",
		'md5sum' => '3f17039f5265e08af377cd8413c77be4',
		"packages" => default['pxe']['common'][:packages],
		"post_script" => default['pxe']['common']["post_script"],
	},
	{
		"id" => "centos-6.3-x86_64",
		"platform" => "centos",
		"arch" => "x86_64",
		"cdimage" => "#{mirrors['centos']}/6.3/isos/x86_64/CentOS-6.3-x86_64-bin-DVD1.iso",
		'md5sum' => 'a991defc0a602d04f064c43290df0131',
		"packages" => "ntp",
		"post_script" => "chkconfig ntpd on
ntpdate -b -u pool.kr.ntp.org
get -O /etc/dhclient-enter-hooks http://#{node[:ipaddress]}/files/sethostname.sh
echo 'proxy=http://#{node[:ipaddress]}:3128' >> /etc/yum.conf",
	},
]
# vim: ts=4 sw=4 nu sw=4 ai
