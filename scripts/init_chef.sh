#!/bin/bash
set -e

dir=`dirname $0`
if [ -f "$dir/init_chef.rc" ]; then
	source "$dir/init_chef.rc"
fi

revert=${revert:-true}
snapshot=${snapshot:-os_setup}
create_vm=${create_vm:-true}
compute_count=${compute_count:-2}
chef_bootstrap=${chef_bootstrap:-apt}
chef_env=${chef_env:-dev}
ssh_key=${ssh_key:-~/.ssh/id_rsa.whitekid@gmail.com}

function do_ssh(){
	ssh -i ${ssh_key} root@$@
}

function wait_for() {
	local first=0

	until $1; do
		if [ $first = 0 ]; then
			echo -n $2;
			first=1
		else
			echo -n .
		fi

		sleep $3
	done

	echo
}

function sync_clock() {
	# @note 시간 동기화, 시간이 맞지 않으면 chef-cient가 오류를 낸다.
	# 그리고 시작할 때 ntpd가 startup하면서 포트를 점유하고 있어서 약간 기다리면서 한다.
	do_ssh $1 'until ntpdate -u -b 0.kr.pool.ntp.org; do sleep 3; done; hwclock -w'
}

# restore vm
function _revert_vm() {
	vm=$1

	v=`echo $vm | cut -d : -f 1`
	if [ "$revert" = "true" ]; then
		echo "revert $v to snapshot $snapshot"
		vmrun revertToSnapshot $v $snapshot
		sleep 3
	fi

	until vmrun list | grep "$v" > /dev/null ; do
		echo "starting $v"
		timeout 10 vmrun start $v || true
	done
}

function _role_settled(){
	local roles=$1
	for role in $roles; do
		knife search node "roles:${role}" | grep ^IP > /dev/null || return 1
	done

	return 0
}

for vm in $vms; do
	_revert_vm $vm
done

for vm in $vms; do
	host=`echo $vm | cut -d : -f 2`
	knife node delete $host -y || true
	knife client delete $host -y || true
done

for vm in $vms; do
	# bootstrap chef
	host=`echo $vm | cut -d : -f 2`

	wait_for "do_ssh $host echo -n 2>&1 > /dev/null" "waiting $host to boot up..." 5

	do_ssh $host rm -rf /etc/chef

	sync_clock $host

	release=$(do_ssh $host lsb_release -a | grep Release | awk '{print $2}')

	do_ssh $host '(apt-get purge -y chef; rm -rf /etc/chef)'

	# find roles assign to node
	run_list=''
	domain=choe
	required_role=''
	case $host in
		"syslog.${domain}")
			run_list="role[openstack-syslog-server]"
			;;
		"database.${domain}")
			run_list="role[openstack-database],role[openstack-rabbitmq]"
			;;
		"keystone.${domain}")
			required_role='openstack-database openstack-syslog-server'
			run_list="role[keystone-server]"
			;;
		"control.${domain}")
			required_role='keystone-server'
			run_list="role[openstack-control],role[nova-api]"
			;;
		"c-vol.${domain}")
			required_role='openstack-control'
			run_list="role[cinder-volume]"
			;;
		"network.${domain}")
			required_role='openstack-control'
			run_list="role[openstack-network]"
			;;
		"net-l3.${domain}")
			required_role='openstack-control'
			run_list="role[quantum-l3-agent]"
			;;
		"net-dhcp.${domain}")
			required_role='openstack-control'
			run_list="role[quantum-dhcp-agent]"
			;;
		c-[0-9][0-9]-[0-9][0-9].${domain})
			required_role='openstack-control'
			run_list="role[openstack-compute]"
			;;
		"horizon.${domain}")
			run_list="role[horizon]"
			;;
		*)
			run_list="role[openstack-base]"
			;;
	esac

	# @note bootstrap 하면서 run_list를 추가할 수 있지만, 이 경우 bootstrap에서
	# chef-client가 설정되기까지 기다리기 때문에 다음 작업이 delay된다.
	# 따라서 bootstrap에서는 chef만 설치한다.
	# - 중간에 에러가 나면 node도 등록이 안되는 문제가 있다.
	# - chef-sole로 실행하는군.. 실제 환경과도 약간 다른 문제도
	knife bootstrap $host -d ubuntu${release}-apt -xroot -i ${ssh_key} --bootstrap-version=0.10 -E $chef_env

	wait_for "knife node show $host 2>&1" "waiting $host to chef register..." 3

	[ ! -z "$required_role" ] && wait_for "_role_settled ${required_role}" "waiting role ${required_role}..." 5

	knife node run_list add "${host}" "${run_list}"

	# @note package가 설치되면서 다음 reboot에 적용되는 것들이 있다. 따라서 reboot하는 것이 안전함
	do_ssh $host reboot
done


# create test vm
if [ "$create_vm" == "true" ]; then
	function _nova_compute_up() {
		control_host=$(knife search node roles:openstack-control | awk '/^FQDN/{print $2}')
		test $(do_ssh $control_host nova-manage service list 2>&1 | grep nova-compute | grep -c ':-)') -ge "$compute_count"
	}
	wait_for _nova_compute_up "wait for nova-compute up..." 5

	# launch vm
	do_ssh $control_host << EOF
	. openrc admin

	WITH_FLOATINGIP=true bin/vm_create.sh test0

	ip=\`quantum floatingip-list | head -n 4 | tail -n 1 | awk '{print \$6}'\`

	until ping -c 3 \$ip; do
		sleep 5;
	done
EOF
fi

# vim: nu ai ts=4 sw=4
