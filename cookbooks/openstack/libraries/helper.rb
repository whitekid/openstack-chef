module Openstack
	module Helper
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

		# connection string for sqlachemy/mysql
		def connection_string(dbname, dbuser, dbpass)
			mysql_host = get_roled_host('openstack-database')

			return "mysql://#{dbuser}:#{dbpass}@#{mysql_host}/#{dbname}?charset=utf8"
		end
	end
end
# vim: nu ai ts=4 sw=4
