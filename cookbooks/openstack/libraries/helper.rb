module Helper
	def create_db(dbname, dbuser, dbpass)
		bash "create database #{dbname}" do
			rootpw = data_bag_item('openstack', 'default')['dbpasswd']['mysql']
			code <<-EOF
				mysql -uroot -p#{rootpw} -e 'CREATE DATABASE #{dbname}'
				mysql -uroot -p#{rootpw} -e 'GRANT ALL ON #{dbname}.* TO "#{dbuser}"@"%" IDENTIFIED BY "#{dbpass}"'
			EOF
			not_if "mysql -uroot -p#{rootpw} -e 'show databases' | grep ' #{dbname} '"
		end
	end

	def connection_string(dbname, dbuser, dbpass)
		bag = data_bag_item('openstack', 'default')
		return "mysql://#{dbuser}:#{dbpass}@#{bag["control_host"]}/#{dbname}?charset=utf8"
	end

	def services(svcs)
		svcs.each do | s |
			service s do
				supports :status => true, :restart => true, :reload => true, :stop => true
				action [ :enable, :start ]
			end
		end
	end

	def packages(pkgs)
		pkgs.each do |p|
			package p
		end
	end
end
# vim: nu ai ts=4 sw=4
