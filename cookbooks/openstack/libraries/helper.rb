module Helper
	# mysql helper functions
	def create_db(dbname, dbuser, dbpass)
		package "mysql-client"
		bash "create database #{dbname}" do
			rootpw = data_bag_item('openstack', 'default')['dbpasswd']['mysql']
			code <<-EOF
				mysql -uroot -p#{rootpw} -e 'CREATE DATABASE #{dbname}'
				mysql -uroot -p#{rootpw} -e 'GRANT ALL ON #{dbname}.* TO "#{dbuser}"@"%" IDENTIFIED BY "#{dbpass}"'
			EOF
			not_if "mysql -uroot -p#{rootpw} -e 'show databases' | grep ' #{dbname} '"
		end
	end

	def get_roled_host(role)
		result, _, _ = Chef::Search::Query.new.search(:node, "roles:#{role}")

		if result.length == 0 and node["roles"].include?(role):
			return node['ipaddress']
		end

		return result[0]['ipaddress']
	end

	def connection_string(dbname, dbuser, dbpass)
		mysql_host = get_roled_host('openstack_database')

		return "mysql://#{dbuser}:#{dbpass}@#{mysql_host}/#{dbname}?charset=utf8"
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

	def iface_addr(iface)
		return node["network"]["interfaces"][iface]["addresses"].select { |address, data| data["family"] == "inet" }[0][0]
	end
end
# vim: nu ai ts=4 sw=4
