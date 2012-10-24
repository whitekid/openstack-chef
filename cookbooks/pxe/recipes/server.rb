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

template "#{config_dir}/default" do
	source "pxe_default.cfg.erb"
	mode "0755"
	variables({
		:items => node[:pxe][:items]
	})
end

eth0 = node["network"]["interfaces"]["eth0"]["addresses"].select { |address, data| data["family"] == "inet" }[0][0]
bag = data_bag_item('hosts', 'default')

node[:pxe][:items].each do |item|
	# netboot 파일을 다운받아서 하면 CD 이미지와 커널 모듈 버전이 안맞는다고 나온다.
	# 따라서 CD의 netboot 이미지를 가지고 설정한다.
	pxe_image_dir = "#{node[:tftp][:directory]}/images/#{item[:id]}"

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
			:ipaddr => bag['properties']['pxe_image_host'],
		})
	end

	## copy pxe installer from image
	# @todo copy from image server
	case item[:platform]
	when 'ubuntu'
		files = %w{ linux initrd.gz }
		dir = "install/netboot/ubuntu-installer/#{item[:arch]}"

	when 'centos'
		files = %w{ vmlinuz initrd.img }
		dir = "images/pxeboot"
	end

	files.each do |f|
		# @note remote_file로 가져오는게 이상한데?
		#remote_file "#{pxe_image_dir}/#{f}" do
		#	source = "http://#{bag[:pxe_image_host]}/images/#{item[:id]}/#{dir}/#{f}"
		#	puts "hahaha #{source}"
		#end
		execute "#{pxe_image_dir}/#{f}" do
			command "wget -c -O #{pxe_image_dir}/#{f} http://#{bag['properties']['pxe_image_host']}/images/#{item[:id]}/#{dir}/#{f}"
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

# vim: ts=4 nu sw=4 ai
