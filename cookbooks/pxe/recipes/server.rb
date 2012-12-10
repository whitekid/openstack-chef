::Chef::Recipe.send(:include, Whitekid::Helper)

include_recipe "nginx"
repo_node = get_roled_node('repo')

# copy pxelinux to tftp
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

bag = data_bag_item('hosts', 'default')

node[:pxe][:items].each do |item|
	# @note
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
			:id => item[:id],
			:arch => item[:arch],
			:repo_host => node[:fqdn],
		})
	end

	## copy pxe network installer image
	case item[:platform]
	when :ubuntu
		files = %w{ linux initrd.gz }
		dir = "install/netboot/ubuntu-installer/#{item[:arch]}"

		url_base = "http://#{repo_node[:fqdn]}/#{repo_node[:repo][:ubuntu][:pxe_linux_path]}/dists/#{item[:release]}/main/installer-#{item[:arch]}/current/images/netboot/ubuntu-installer/#{item[:arch]}"

	when :centos
		files = %w{ vmlinuz initrd.img }
		dir = "images/pxeboot"
		url_base = "#{repo_node[:repo][:centos][:url]}/#{item[:release]}/os/#{item[:arch]}/images/pxeboot"
	else
		raise "unsupported platform #{item[:platform]}"
	end

	files.each do |f|
		execute "#{pxe_image_dir}/#{f}" do
			command "wget -c -O #{pxe_image_dir}/#{f} #{url_base}/#{f}"
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

# kickstart, debootstrap file
node[:pxe][:items].each do |item|
	install_image_dir = "#{wwwroot}/images/#{item[:id]}"

	directory "#{wwwroot}/ks/"

	case item[:platform]
	when :centos # kickstart for centos
		template "#{wwwroot}/ks/#{item[:id]}.ks" do
			source "#{item[:platform]}.ks.erb"
			mode "0644"
			variables({
				:repo => repo_node[:repo][:centos][:url],
				:release => item[:release],
				:arch => item[:arch],
				:packages => item[:packages],
				:post_script => item[:post_script],
				:host => node[:fqdn],
				:rootpw => node[:pxe][:root][:passwd_crypted],
				:initial_user => node[:pxe][:initial_user][:username],
				:ssh_key => node[:pxe][:ssh_key],
			})
		end
	when :ubuntu	# preceed for ubuntu
		template "#{wwwroot}/ks/#{item[:id]}.seed" do
			source "#{item[:platform]}.seed.erb"
			mode "0644"
			variables({
				:packages => item[:packages],
				:repo_host => repo_node[:fqdn],
				:repo_dir => repo_node[:repo][:ubuntu][:pkg_path],
				:host => node[:fqdn],
				:rootpw => node[:pxe][:root][:passwd_crypted],
				:initial_user => node[:pxe][:initial_user][:username],
				:initial_user_fullname => node[:pxe][:initial_user][:fullname],
				:initial_user_passwd => node[:pxe][:initial_user][:passwd_crypted],
				:ssh_key => node[:pxe][:ssh_key],
			})
		end
	end
end

# ssh key for root access
cookbook_file "#{wwwroot}/ks/#{node[:pxe][:ssh_key]}" do
	source node[:pxe][:ssh_key]
	mode "0644"
	not_if { node[:pxe][:ssh_key].nil? }
end

template "#{wwwroot}/ks/key.sh" do
	mode "0644"
	not_if { node[:pxe][:ssh_key].nil? }
	variables({
		:initial_user => node[:pxe][:initial_user][:username],
		:host => node[:fqdn],
		:ssh_key => node[:pxe][:ssh_key],
	})
end

# vim: ts=4 nu sw=4 ai
