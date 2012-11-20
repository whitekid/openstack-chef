wwwroot='/var/www'

eth0 = node["network"]["interfaces"]["eth0"]["addresses"].select { |address, data| data["family"] == "inet" }[0][0]

node[:pxe][:items].each do |item|
	install_image_dir = "#{wwwroot}/images/#{item[:id]}"

	directory "#{wwwroot}/ks/"

	case item[:platform]
	when 'centos' # kickstart for centos
		template "#{wwwroot}/ks/#{item[:id]}.ks" do
			source "#{item[:platform]}.ks.erb"
			mode "0644"
			variables({
				:id => item[:id],
				:mirror_host => item[:mirror_host],
				:mirror_path => item[:mirror_path],
				:release => item[:release],
				:arch => item[:arch],
				:packages => item[:packages],
				:post_script => item[:post_script]
			})
		end
	when 'ubuntu'	# preceed for ubuntu
		template "#{wwwroot}/ks/#{item[:id]}.seed" do
			source "#{item[:platform]}.seed.erb"
			mode "0644"
			variables({
				:id => item[:id],
				:ipaddr => eth0,
				:packages => item[:packages],
				:mirror_host => item[:mirror_host],
				:mirror_path => item[:mirror_path],
			})
		end
	end
end


#
# predownload cloud-images for cache
#
directory "#{wwwroot}/cloud-images"

images=%w{https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img
http://uec-images.ubuntu.com/releases/precise/release-20121001/ubuntu-12.04-server-cloudimg-amd64-disk1.img
http://uec-images.ubuntu.com/releases/quantal/release-20121017/ubuntu-12.10-server-cloudimg-amd64-disk1.img
}

images=%w{
http://192.168.100.108:8080/uec-images/cirros-0.3.0-x86_64-disk.img
http://192.168.100.108:8080/uec-images/releases/precise/20121026.1/ubuntu-12.04-server-cloudimg-amd64-disk1.img
http://192.168.100.108:8080/uec-images/releases/quantal/20121017/ubuntu-12.10-server-cloudimg-amd64-disk1.img
}

images.each do |image|
	local_file = "#{wwwroot}/cloud-images/#{File.basename(image)}"
	puts local_file

	execute "download cloudimage #{image}" do
		command "wget -c -O #{local_file} #{image}"
		not_if { File.exist?(local_file) }
	end
end

# vim: nu ai ts=4 sw=4
