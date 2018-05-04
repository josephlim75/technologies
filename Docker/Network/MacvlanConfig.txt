## Removing Bridge

    $ifconfig <bridge name> down
    
    $ sudo ip link delete br0 type bridge
	

PreRequisites
	yum install bridge-utils libvirt
------------------------------------------------------------------------------------------------------------------------------------------

Promiscuous Mode
	To check if the promiscuous mode is on run:
		netstat -i

		Kernel Interface table
		Iface MTU  RX-OK RX-ERR RX-DRP RX-OVR TX-OK TX-ERR TX-DRP TX-OVR Flg
		eth0  9001 9095  0      0      0      10367 0       0     0      BMRU

		Look at the Flg column – if the P flag is missing the mode is not enabled.

		To enable it run:

			ifconfig eth0 promisc
		or

			ip link set eth0 promisc on
------------------------------------------------------------------------------------------------------------------------------------------
Custom Docker docker_gwbridge
	docker network create --subnet 192.169.1.2/24 --opt com.docker.network.bridge.name=docker_gwbridge --opt com.docker.network.bridge.enable_icc=false docker_gwbridge

	CentOS 7 /usr/share/doc/initscripts-9.49.24/sysconfig.txt says:

	https://unix.stackexchange.com/questions/198076/enable-promiscous-mode-in-centos-7
	    No longer supported:
	    PROMISC=yes|no (enable or disable promiscuous mode)
        ALLMULTI=yes|no (enable or disable all-multicast mode)
		So for enabling you have to run:

		ip link set ethX promisc on
		Or if you want to happen on boot you can use systemd service rc-local.
		Put the above line in /etc/rc.d/rc.local (don't forget to change ethX with your proper device), then:

		chmod u+x /etc/rc.d/rc.local
		systemctl enable rc-local
		systemctl start rc-local
		shareimprove this answer


docker network create --config-only --subnet 172.18.10.0/24 --gateway 172.18.10.1 -o parent=ens224 --ip-range 192.168.99.100/24 mv-config

docker network create --config-only --subnet 192.168.99.0/24 --gateway 192.168.99.1 -o parent=ens192 --ip-range 192.168.99.100/24 mv-config

docker network create -d macvlan --scope swarm --config-from mv-config --attachable mv-net

Add 2nd ip address on existing interface
	ip address add 192.168.99.37/24 dev eth0
Up a device
	ip link set dev eth0.1098.br up
Create Interface

	ip link add ens192.br link ens192 type macvlan mode bridge
	ip addr add 192.168.99.0/24 dev ens192.br
	ip link set dev ens192.br up
	
	ip link del dev ens192.br

	
HOST 1
docker network  create  -d macvlan --subnet=172.18.0.0/23 --ip-range=172.18.1.0/24 -o macvlan_mode=bridge -o parent=ens192 macvlan
docker run --net=macvlan -it --name macvlan_1 --rm alpine /bin/sh


docker network  create  -d macvlan --subnet=172.18.0.0/23 --gateway=172.18.0.1 --ip-range=172.18.1.0/24 -o macvlan_mode=bridge -o parent=ens192 macvlan
