# @todo squid가 설정이 완료되기도 전에 이 recipe에서 proxy를 사용하는 문제가 있음

config_dir = "#{node['tftp']['directory']}/pxelinux.cfg"

directory config_dir

package "syslinux-common"
wwwroot='/var/www'

["pxelinux.0", "menu.c32"].each do |f|
	execute "#{node[:tftp][:directory]}/#{f}" do
		command "cp /usr/lib/syslinux/#{f} #{node[:tftp][:directory]}/#{f}"
		not_if { File.exist?("#{node[:tftp][:directory]}/#{f}") }
	end
end

# TODO: pxelinux.cfg/default 만들기
template "#{config_dir}/default" do
	source "pxe_default.cfg.erb"
	mode "0755"
	variables({
		:items => node[:pxe][:items]
	})
end

eth0 = node["network"]["interfaces"]["eth0"]["addresses"].select { |address, data| data["family"] == "inet" }[0][0]

# @todo md5sum for iso images
node[:pxe][:items].each do |item|
	# install from netboot
	# netboot 파일을 다운받아서 하면 CD 이미지와 커널 모듈 버전이 안맞는다고 나온다.
	# 따라서 CD의 netboot 이미지를 가지고 설정한다.
	pxe_image_dir = "#{node[:tftp][:directory]}/images/#{item[:id]}"
	install_image_dir = "#{wwwroot}/images/#{item[:id]}"

	directory pxe_image_dir do
		recursive true
	end

	# pxe configuration file
	template "#{config_dir}/#{item[:id]}" do
		source "pxelinux.cfg-#{item[:platform]}.erb"
		mode "0644"
		variables({
			:id => item["id"],
			:arch => item["arch"],
			:ipaddr => eth0,
		})
	end

	## kickstart
	directory "#{wwwroot}/ks/"
	template "#{wwwroot}/ks/#{item[:id]}.ks" do
		source "#{item[:platform]}.ks.erb"
		mode "0644"
		variables({
			:id => item[:id],
			:ipaddr => eth0,
			:packages => item[:packages],
			:post_script => item[:post_script]
		})
	end

	# CDImage Download
	local_file="/var/cache/#{item[:id]}.iso"
	bash "download iso file: #{item[:cdimage]}" do
		code <<-EOH
		wget -O #{local_file} -nv #{item[:cdimage]}
		EOH
		not_if { File.exists?(local_file) }
	end

	directory install_image_dir do
		recursive true
	end

	package "fuseiso"

	# mount cd
	mount install_image_dir do
		device local_file
		fstype "fuse.fuseiso"
		options "allow_other"
		not_if "mount | grep fuseiso | grep '#{item[:id]} '"
	end

	## copy pxe installer
	case item[:platform]
	when 'ubuntu'
		files = %w{ linux initrd.gz }
		dir = "install/netboot/ubuntu-installer/#{item[:arch]}"

	when 'centos'
		files = %w{ vmlinuz initrd.img }
		dir = "images/pxeboot"
	end

	files.each do |f|
		if File.exists?("#{install_image_dir}/#{dir}/#{f}")
			File "#{pxe_image_dir}/#{f}" do
				content IO.read("#{install_image_dir}/#{dir}/#{f}")
				action :create_if_missing
			end
		end
	end
end



# mac address에 대응하는 설정
data_bag_item('hosts', 'default')['subnets'].each do |subnet|
	subnet["hosts"].each do |host|
		mac = host["mac"].gsub(':', '-').downcase

		link "#{config_dir}/01-#{mac}" do
			to host["os"]
			not_if { host["os"].nil? }
		end
	end
end

#
# predownload cloud-images for cache
#
directory "#{wwwroot}/cloud-images"
%w{https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img
http://uec-images.ubuntu.com/releases/precise/release-20121001/ubuntu-12.04-server-cloudimg-amd64-disk1.img}.each do |image|
	local_file = "#{wwwroot}/cloud-images/#{File.basename(image)}"
	puts local_file

	execute "download cloudimage #{image}" do
		command "wget -c -O #{local_file} #{image}"
		not_if { File.exist?(local_file) }
	end
end

# interfaces to listen pxe boot
node['pxe']['interfaces'].each do | x |
	ifconfig x[1] do
		device x[0]
		mask '255.255.255.0'
	end
end

#
# nfs-server 설정: 임시로...
#
include_recipe "nfs::server"

# 개발용 캐쉬라구요..
%w{git_cache pip_cache}.each do |path|
	directory "/nfs/#{path}" do
		recursive true
		mode "0777"
	end
end

template "/etc/exports" do
	source "exports.erb"
	notifies :restart, resources(:service => node['nfs']['service']['server'])
end
	#mode "0644"
# vim: ts=4 nu sw=4 ai
