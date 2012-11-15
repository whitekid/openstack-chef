#!/bin/bash
set -e

dir=`dirname $0`
if [ -f "$dir/init_chef.rc" ]; then
	source "$dir/init_chef.rc"
fi

vm_path=${vm_path:-"~/vmware/openstack"}
vms+="${vm_path}/database/database.vmx:10.20.1.4 "
vms+="${vm_path}/control/control.vmx:10.20.1.6 "
vms+="${vm_path}/cinder-volume/cinder-volume.vmx:10.20.1.7 "
vms+="${vm_path}/net-l3/net-l3.vmx:10.20.1.201 "
vms+="${vm_path}/net-dhcp/net-dhcp.vmx:10.20.1.202 "
vms+="${vm_path}/c-01-01/c-01-01.vmx:10.20.1.10 "
vms+="${vm_path}/c-01-02/c-01-02.vmx:10.20.1.11 "

function do_ssh(){
	sshpass -pchoe ssh root@$@
}

function wait_for() {
	until $1; do
		echo $2
		sleep $3
	done
}

function sync_clock() {
	# @note 시간 동기화, 시간이 맞지 않으면 chef-cient가 오류를 낸다.
	# 그리고 시작할 때 ntpd가 startup하면서 포트를 점유하고 있어서 약간 기다리면서 한다.
	do_ssh $ip 'until ntpdate -u -b pool.ntp.org; do sheep 3; done; hwclock -w'
}

# restore vm
vm_revert=${vm_revert:-true}
vm_snapshot=${vm_snapshot:-created}

for vm in $vms; do
	if [ "$vm_revert" = "true" ]; then
		v=`echo $vm | cut -d : -f 1`
		echo "revert $v to snapshot $vm_snapshot"
		vmrun revertToSnapshot $v $vm_snapshot
		sleep 1
		echo "starting $v"
		vmrun start $v
	fi

	# bootstrap chef
	ip=`echo $vm | cut -d : -f 2`

	wait_for "do_ssh $ip echo" "waiting $node($ip) to boot up..." 3

	do_ssh $ip rm -rf /etc/chef
	node="$(do_ssh $ip hostname -f)"

	sync_clock

	release=$(do_ssh $ip lsb_release -a | grep Release | awk '{print $2}')

	knife node delete $node -y || true
	knife client delete $node -y || true

	do_ssh $ip '(apt-get purge -y --auto-remove chef; rm -rf /etc/chef)'

	# quantal은 gem 버전으로 설치하면 되고 아래 파일을 추가한다
	# /etc/init.d/chef-client # 여기에는 경로 수정이 필요함
	# /etc/default/chef-client
	knife bootstrap $ip -d ubuntu${release}-apt -xroot -Pchoe \
		--bootstrap-version=0.10 --bootstrap-proxy=http://10.20.1.3:3128

	# @note 재시작해야 chef가 클라이언트를 등록한다.
	sync_clock
	do_ssh $ip service chef-client restart

	wait_for "knife node show $node" "waiting $node($ip) to chef register..." 3

	run_list=''
	domain=choe
	case $node in
		"database.${domain}")
			run_list="role[openstack_database]"
			;;
		"control.${domain}")
			run_list="role[openstack_control]"
			;;
		"c-vol.${domain}")
			run_list="role[cinder_volume]"
			;;
		"network.${domain}")
			run_list="role[openstack_network]"
			;;
		"net-l3.${domain}")
			run_list="role[quantum_l3]"
			;;
		"net-dhcp.${domain}")
			run_list="role[quantum_dhcp]"
			;;
		c-[0-9][0-9]-[0-9][0-9].${domain})
			run_list="role[openstack_compute]"
			;;
		*)
			run_list="role[openstack_base]"
			;;
	esac

	knife node run_list add "${node}" "${run_list}"

	# reboot to apply chef role
	do_ssh $ip reboot

	# 
	if [ $node = 'control.${domain}' ]; then
		echo "@todo wait until api server up"
	fi
done

# vim: nu ai ts=4 sw=4
