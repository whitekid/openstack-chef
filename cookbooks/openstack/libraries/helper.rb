module Helper
	# mysql helper functions
	def create_db(dbname, dbuser, dbpass)
		package "mysql-client"

		rootpw = get_roled_node('openstack-database')['mysql']['server_root_password']
		bash "create database #{dbname}" do
			code <<-EOF
				mysql -uroot -p#{rootpw} -e 'CREATE DATABASE #{dbname}'
				mysql -uroot -p#{rootpw} -e 'GRANT ALL ON #{dbname}.* TO "#{dbuser}"@"%" IDENTIFIED BY "#{dbpass}"'
			EOF
			not_if "mysql -uroot -p#{rootpw} -e 'show databases' | grep ' #{dbname} '"
		end
	end

	def get_roled_node(role)
		result, _, _ = Chef::Search::Query.new.search(:node, "roles:#{role}")

		if result.length == 0 
			if node["roles"].include?(role):
				return node	# this node
			end

			msg = "Cannot find node for role '#{role}'"
			Chef::Log.fatal(msg)
			raise msg
		end

		return result[0]
	end

	def get_roled_host(role)
		return get_roled_node(role)['ipaddress']
	end

	def connection_string(dbname, dbuser, dbpass)
		mysql_host = get_roled_host('openstack-database')

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
