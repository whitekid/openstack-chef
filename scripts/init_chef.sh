#!/bin/bash
set -e

dir=`dirname $0`
if [ -f "$dir/init_chef.rc" ]; then
	source "$dir/init_chef.rc"
fi

revert=${revert:-true}
snapshot=${snapshot:-os_setup}
create_vm=${create_vm:-true}
chef_bootstrap=${chef_bootstrap:-apt}
compute_count=${compute_count:-2}

function do_ssh(){
	sshpass -pchoe ssh root@$@
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
	do_ssh $ip 'until ntpdate -u -b pool.ntp.org; do sheep 3; done; hwclock -w'
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
		vmrun start $v
		sleep 3
	done
}

function _role_settled(){
	knife search node roles:$required_role | grep ^IP > /dev/null
	return $?
}

for vm in $vms; do
	_revert_vm $vm
done

for vm in $vms; do
	# bootstrap chef
	ip=`echo $vm | cut -d : -f 2`

	wait_for "do_ssh $ip echo 2>&1 > /dev/null" "waiting $ip to boot up..." 5

	do_ssh $ip rm -rf /etc/chef
	node="$(do_ssh $ip hostname -f)"

	sync_clock

	release=$(do_ssh $ip lsb_release -a | grep Release | awk '{print $2}')

	knife node delete $node -y || true
	knife client delete $node -y || true

	do_ssh $ip '(apt-get purge -y chef; rm -rf /etc/chef)'

	# quantal은 gem 버전으로 설치하면 되고 아래 파일을 추가한다
	# /etc/init.d/chef-client # 여기에는 경로 수정이 필요함
	# /etc/default/chef-client
	knife bootstrap $ip -d ubuntu${release}-apt -xroot -Pchoe --bootstrap-version=0.10

	# @note 재시작해야 chef가 클라이언트를 등록한다.
	sync_clock
	do_ssh $ip service chef-client restart || true

	wait_for "knife node show $node 2>&1" "waiting $node($ip) to chef register..." 3

	run_list=''
	domain=choe
	required_role=''
	case $node in
		"database.${domain}")
			run_list="role[openstack-database],role[openstack-rabbitmq]"
			;;
		"keystone.${domain}")
			required_role='openstack-database'
			run_list="role[keystone-server]"
			;;
		"control.${domain}")
			required_role='keystone-server'
			run_list="role[openstack-control]"
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

	[ ! -z "$required_role" ] && wait_for "_role_settled ${required_role}" "waiting installing ${required_role} role..." 5
	knife node run_list add "${node}" "${run_list}"

	# reboot to apply chef role
	do_ssh $ip reboot
done


# create test vm
if [ "$create_vm" == "true" ]; then
	control_ip=$(knife search node roles:openstack-control | awk '/^IP/{print $2}')
	function _nova_compute_up() {
		test $(do_ssh $control_ip nova-manage service list 2>&1 | grep nova-compute | grep -c ':-)') -ge "$compute_count"
	}
	wait_for _nova_compute_up "wait for nova-compute up..." 5

	# launch vm
	do_ssh $control_ip << EOF
	. openrc admin

	WITH_FLOATINGIP=true bin/vm_create.sh test0

	ip=\`quantum floatingip-list | head -n 4 | tail -n 1 | awk '{print \$6}'\`

	until ping -c 3 \$ip; do
		sleep 5;
	done
EOF
fi

# vim: nu ai ts=4 sw=4
