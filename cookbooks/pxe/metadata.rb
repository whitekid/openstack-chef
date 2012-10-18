maintainer       "YOUR_COMPANY_NAME"
maintainer_email "YOUR_EMAIL"
license          "All rights reserved"
description      "Installs/Configures pxe"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

depends		"tftp"
depends		"nginx"
depends		"nfs"	# pxeboot 서버는 임시로 nfs 서버로 활용함
