wwwroot='/var/www'

eth0 = node["network"]["interfaces"]["eth0"]["addresses"].select { |address, data| data["family"] == "inet" }[0][0]

# @todo md5sum for iso images
node[:pxe][:items].each do |item|
	install_image_dir = "#{wwwroot}/images/#{item[:id]}"

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

	# mount install cd
	package "fuseiso"
	mount install_image_dir do
		device local_file
		fstype "fuse.fuseiso"
		options "allow_other"
		not_if "mount | grep fuseiso | grep '#{item[:id]} '"
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

# vim: ts=4 nu sw=4 ai
