# 호스트 정의
#
# 이 내용을 여기에 둘 것인지 데이터백에 둘 것인지 고민이 있었으나...
# 우선 여기에 두고, dhcp recipe에서 tftp의 파일을 변경하는 것으로 우선 간다.

default["dhcp"]["subnets"] = [
	{
		"id" => "management rack",
		"vmnet" => "vmnet2",
		"network" => "10.20.1.0",
		"netmask" => "255.255.255.0",
		"gateway" => "10.20.1.1",
		"range"   => "10.20.1.20 10.20.1.49",
		"next-server" => "10.20.1.3",
		"hosts" => [
			{"hostname" => "chef-server",	"mac" => "00:0C:29:C3:CA:30", "ip" => "10.20.1.5", "role" => nil},
			{"hostname" => "control",	"mac" => "00:50:56:30:1C:F4", "ip" => "10.20.1.6", "role" => 'control'},

			# for testing
			{"hostname" => "centos-sandbox","mac" => "00:0C:29:DE:12:0E", "ip" => "10.20.1.51", "os" => "centos-6.3", "role" => nil},
			{"hostname" => "ubuntu-sandbox","mac" => "00:0C:29:97:D4:E1", "ip" => "10.20.1.61", "role" => nil},
			{"hostname" => "ubuntu-sandbox-dev","mac" => "00:0C:29:65:96:63", "ip" => "10.20.1.71", "role" => nil},
		]
	},
	{
		"id" => "compute rack 01",
		"vmnet" => "vmnet3",
		"network" => "10.30.1.0",
		"netmask" => "255.255.255.0",
		"gateway" => "10.30.1.1",
		"range"   => "10.30.1.20 10.30.1.49",
		"next-server" => "10.30.1.3",
		"hosts" => [
			{"hostname" => "c-01-01", "mac" => "00:50:56:32:72:BE", "ip" => "10.30.1.20", "role" => 'compute'},
			{"hostname" => "c-01-02", "mac" => "00:50:56:29:03:87", "ip" => "10.30.1.21", "role" => 'compute'},
		]
	},
	{
		"id" => "compute rack 02",
		"vmnet" => "vmnet4",
		"network" => "10.30.2.0",
		"netmask" => "255.255.255.0",
		"gateway" => "10.30.2.1",
		"range"   => "10.30.2.20 10.30.2.49",
		"next-server" => "10.30.2.3",
		"hosts" => [
			{"hostname" => "c-02-01", "mac" => "00:50:56:22:4E:F8", "ip" => "10.30.2.20", "role" => 'compute'},
			{"hostname" => "c-02-02", "mac" => "00:50:56:31:18:DD", "ip" => "10.30.2.21", "role" => 'compute'},
		]
	},
	{
		"id" => "network rack",
		"vmnet" => "vmnet5",
		"network" => "10.40.1.0",
		"netmask" => "255.255.255.0",
		"gateway" => "10.40.1.1",
		"range"   => "10.40.1.20 10.40.1.49",
		"next-server" => "10.40.1.3",
		"hosts" => [
			{"hostname" => "network", "mac" => "00:50:56:3E:83:56", "ip" => "10.40.1.5", "role" => 'network'},
		]
	},
]

# vim: ts=4
