# 패키징 미러링 서버 설정
# my personal mirror with apt-mirror
pkg_mirror = {
	'ubuntu' => {
		'host' => '192.168.100.108:8080',
		'path' => '/apt-mirror/ftp.daum.net/ubuntu',
	},
	'centos' => {
		'host' => '192.168.100.108:8080',
		'path' => '/centos',
	}
}

# Setup ISO mirrors
iso_mirror = {
	'ubuntu' => "http://192.168.100.108:8080/ubuntu-cd",
	'centos' => "http://192.168.100.108:8080/centos",
}

default['pxe']['items'] = [
	{
		"id" => "ubuntu-12.04-amd64",
		"platform" => "ubuntu",
		"arch" => "amd64",
		"release" => "precise",
		"packages" => "ntp openssh-server vim",
		'mirror_host' => pkg_mirror['ubuntu']['host'],
		'mirror_path' => pkg_mirror['ubuntu']['path'],
		"post_script" => "",
	},
	# @note 12.04는 현재 pxeboot가 정상 작동하지 않고 있다.
	{
		"id" => "ubuntu-12.10-amd64",
		"platform" => "ubuntu",
		"arch" => "amd64",
		"release" => "precise",
		"packages" => "ntp openssh-server vim",
		'mirror_host' => pkg_mirror['ubuntu']['host'],
		'mirror_path' => pkg_mirror['ubuntu']['path'],
		"post_script" => "",
	},
	{
		"id" => "centos-6.3-x86_64",
		"platform" => "centos",
		"arch" => "x86_64",
		"release" => "6.3",
		"packages" => "ntp",
		'mirror_host' => pkg_mirror['centos']['host'],
		'mirror_path' => pkg_mirror['centos']['path'],
		"post_script" => "",
	},
]


# vim: ts=4 sw=4 nu sw=4 ai
