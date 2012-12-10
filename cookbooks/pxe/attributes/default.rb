default[:pxe][:items] = [
	{
		:id => "ubuntu-12.04-amd64",
		:platform => :ubuntu,
		:arch => :amd64,
		:release => :precise,
		:packages => "ntp openssh-server vim",
		:post_script => "",
	},
	# @note 12.04는 현재 pxeboot가 정상 작동하지 않고 있다.
	{
		:id => "ubuntu-12.10-amd64",
		:platform => :ubuntu,
		:arch => :amd64,
		:release => :precise,
		:packages => "ntp openssh-server vim",
		:post_script => "",
	},
	{
		:id => "centos-6.3-x86_64",
		:platform => :centos,
		:arch => :x86_64,
		:release => "6.3",
		:packages => :ntp,
		:post_script => "",
	},
]

# users
default[:pxe][:root][:passwd_crypted] = 'b5aa09132da3f90af282a3b958c4030c'
default[:pxe][:initial_user][:username] = 'choe'
default[:pxe][:initial_user][:full_name] = 'Choe, Cheng-Dae'
default[:pxe][:initial_user][:passwd_crypted] = 'b5aa09132da3f90af282a3b958c4030c'

# ssh public key
default[:pxe][:ssh_key] = nil

# vim: ts=4 sw=4 nu sw=4 ai
