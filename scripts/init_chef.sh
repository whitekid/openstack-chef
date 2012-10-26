#!/bin/bash
#vm_snapshot=os_setup
vm_snapshot=created

chef_bootstrap='apt'
# gems 버전은 init 스크립트를 수동으로 등록해야하는 문제가 있음
# 12.10은 정식으로 apt가 나오기 전까지는 사용하지 않을 거다.
#chef_bootstrap='gems'

vm_revert=true

vms+="/home/choe/vmware/openstack-devstack/control/control.vmx:10.20.1.6 "
vms+="/home/choe/vmware/openstack-devstack/network/network.vmx:10.30.1.5 "
vms+="/home/choe/vmware/openstack-devstack/c-01-01/c-01-01.vmx:10.30.1.20 "
vms+="/home/choe/vmware/openstack-devstack/c-01-02/c-01-02.vmx:10.30.1.21 "
#vms+="/home/choe/vmware/openstack-devstack/c-02-01/c-02-01.vmx:10.30.1.22 "
#vms+="/home/choe/vmware/openstack-devstack/c-02-02/c-02-02.vmx:10.30.1.23 "

#vms="/home/choe/vmware/openstack-devstack/c-01-01/c-01-01.vmx:10.30.1.20 "
#vms="/home/choe/vmware/openstack-devstack/c-02-02/c-02-02.vmx:10.30.1.23 "

# restore vm
if [ "$vm_revert" = "true" ]; then
	for vm in $vms; do
		v=`echo $vm | cut -d : -f 1`
		echo "revert $v to snapshot $vm_snapshot"
		vmrun revertToSnapshot $v $vm_snapshot
		sleep 3
		echo "starting $v"
		vmrun start $v
	done
fi

# bootstrap chef
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

for vm in $vms; do
	ip=`echo $vm | cut -d : -f 2`

	wait_for "do_ssh $ip echo" "waiting $node($ip) to boot up..." 3

	do_ssh $ip rm -rf /etc/chef
	node="$(do_ssh $ip hostname -f)"

	sync_clock

	release=$(do_ssh $ip lsb_release -a | grep Release | awk '{print $2}')

	knife node delete $node -y
	knife client delete $node -y

	do_ssh $ip '(apt-get purge -y --auto-remove chef; rm -rf /etc/chef)'

	# quantal은 gem 버전으로 설치하면 되고 아래 파일을 추가한다
	# /etc/init.d/chef-client # 여기에는 경로 수정이 필요함
	# /etc/default/chef-client
	knife bootstrap $ip -d ubuntu${release}-${chef_bootstrap} -xroot -Pchoe \
		--bootstrap-version=0.10 --bootstrap-proxy=http://10.20.1.3:3128

	if [ $chef_bootstrap = 'gems' ]; then
		sshpass -pchoe scp ~/bin/chef-client_init.d root@$ip:/etc/init.d/chef-client
		sshpass -pchoe scp ~/bin/chef-client_default root@$ip:/etc/default/chef-client
	fi

	# @note 재시작해야 chef가 클라이언트를 등록한다.
	sync_clock
	do_ssh $ip service chef-client restart

	wait_for "knife node show $node" "waiting $node($ip) to chef register..." 3

	run_list=''
	case $node in
		"control.choe")
			run_list='role[openstack_control]'
			;;
		"network.choe")
			run_list='role[openstack_network]'
			;;
		c-*.choe)
			run_list='role[openstack_compute]'
			;;
	esac

	knife node run_list add $node $run_list

	# reboot to apply chef role
	do_ssh $ip reboot
done

# vim: nu ai ts=4 sw=4
