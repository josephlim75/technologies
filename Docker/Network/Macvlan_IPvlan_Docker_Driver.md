# Gist is at https://gist.github.com/nerdalert/9dcb14265a3aea336f40
#
# Macvlan/Ipvlan Manual Driver Tests
#  -Bash script form at: https://github.com/nerdalert/dotfiles/blob/master/ipvlan-macvlan-it.sh
############################################################################################
# Macvlan IPv4 802.1q VLAN Tagged Bridge Mode Tests
#
### Network w/o explicit mode to default to -o macvlan_mode=bridge VLAN ID:33
docker network create -d macvlan  \
         --subnet=192.168.33.0/24  \
         --gateway=192.168.33.1  \
         -o host_iface=eth1.33 macnet33
         
### Network w/o explicit macvlan_mode=(defaults to bridge)
docker network create -d macvlan  \
         --subnet=192.168.34.0/24  \
         --gateway=192.168.34.1  \
         -o host_iface=eth1.34 macnet34
         
### Network with a GW: ,254 & VLAN ID:35
docker network create -d macvlan  \
         --subnet=192.168.35.0/24  \
         --gateway=192.168.35.254  \
         -o host_iface=eth1.35 macnet35
         
### Network w/o explicit --gateway=(libnetqork ipam defaults to .1)
docker network create -d macvlan  \
         --subnet=192.168.36.0/24  \
         -o host_iface=eth1.36  \
         -o macvlan_mode=bridge macnet36
         
### Network w/ GW: .254, w/o explicit --macvlan_mode
docker network create -d macvlan  \
         --subnet=192.168.37.0/24  \
         --gateway=192.168.37.254  \
         -o host_iface=eth1.37  \
         -o macvlan_mode=bridge macnet37
### No Gateway specified test (defaults to x.x.x.1 as a gateway)

docker network create -d macvlan  \
         --subnet=192.168.38.0/24  \
         -o host_iface=eth1.38  \
         -o macvlan_mode=bridge macnet38
         
### No Gateway specified test (defaults to x.x.x.1 as a gateway)
docker network create -d macvlan  \
         --subnet=192.168.39.0/24  \
         -o host_iface=eth1.39  \
         -o macvlan_mode=bridge macnet39
         
### Start containers on each network
    docker run --net=macnet33 --name=macnet33_test -itd alpine /bin/sh
    docker run --net=macnet34 --name=macnet34_test -itd alpine /bin/sh
    docker run --net=macnet35 --name=macnet35_test -itd alpine /bin/sh
    docker run --net=macnet36 --name=macnet36_test -itd alpine /bin/sh

### Start containers with explicit --ip4 addrs
    docker run --net=macnet37 --name=macnet37_test --ip=192.168.37.10 -itd alpine /bin/sh
    docker run --net=macnet38 --name=macnet38_test --ip=192.168.38.10 -itd alpine /bin/sh
    docker run --net=macnet39 --name=macnet39_test --ip=192.168.39.10 -itd alpine /bin/sh
    
############################################################################################
# Ipvlan IPv4 802.1q VLAN Tagged Bridge Mode Tests
#
#
### Network w/o explicit mode to default to -o ipvlan_mode=l2 VLAN ID:43
docker network create -d ipvlan  \
         --subnet=192.168.43.0/24  \
         --gateway=192.168.43.1  \
         -o host_iface=eth1.43 ipnet43
         
### Network w/o explicit ipvlan_mode=(defaults to l2 if unspecified)
docker network create -d ipvlan  \
         --subnet=192.168.44.0/24  \
         --gateway=192.168.44.1  \
         -o host_iface=eth1.44 ipnet44
         
### Network with a GW: ,254 & VLAN ID:45
docker network create -d ipvlan  \
         --subnet=192.168.45.0/24  \
         --gateway=192.168.45.254  \
         -o host_iface=eth1.45 ipnet45
         
### Network w/o explicit --gateway=(libnetqork ipam defaults to .1)
docker network create -d ipvlan  \
         --subnet=192.168.46.0/24  \
         -o host_iface=eth1.46  \
         -o ipvlan_mode=l2 ipnet46
         
### Network w/ GW: .254, w/o explicit --ipvlan_mode
docker network create -d ipvlan  \
         --subnet=192.168.47.0/24  \
         --gateway=192.168.47.254  \
         -o host_iface=eth1.47  \
         -o ipvlan_mode=l2 ipnet47
         
### No Gateway specified test (defaults to x.x.x.1 as a gateway)
docker network create -d ipvlan  \
         --subnet=192.168.48.0/24  \
         -o host_iface=eth1.48  \
         -o ipvlan_mode=l2 ipnet48
         
### No Gateway specified test (defaults to x.x.x.1 as a gateway)
docker network create -d ipvlan  \
         --subnet=192.168.49.0/24  \
         -o host_iface=eth1.49  \
         -o ipvlan_mode=l2 ipnet49
         
### Start containers on each network
docker run --net=ipnet43 --name=ipnet43_test -itd alpine /bin/sh
docker run --net=ipnet44 --name=ipnet44_test -itd alpine /bin/sh
docker run --net=ipnet45 --name=ipnet45_test -itd alpine /bin/sh
docker run --net=ipnet46 --name=ipnet46_test -itd alpine /bin/sh
    
### Start containers with explicit --ip4 addrs
docker run --net=ipnet47 --name=ipnet47_test --ip=192.168.47.10 -itd alpine /bin/sh
docker run --net=ipnet48 --name=ipnet48_test --ip=192.168.48.10 -itd alpine /bin/sh
docker run --net=ipnet49 --name=ipnet49_test --ip=192.168.49.10 -itd alpine /bin/sh
    
############################################################################################
# Ipvlan IPv4 802.1q VLAN Tagged L2 Mode Tests
#
#
### Gateway is always ignored in L3 mode - default is 'default dev eth(n)'
docker network create -d ipvlan  \
         --subnet=192.168.53.0/24  \
         --gateway=192.168.53.1  \
         -o host_iface=eth1.53 ipnet53
         
### Network w/o explicit ipvlan_mode=(defaults to l3 if unspecified)
docker network create -d ipvlan  \
         --subnet=192.168.54.0/24  \
         --gateway=192.168.54.1  \
         -o host_iface=eth1.54 ipnet54
         
### Gateway is always ignored in L3 mode - default is 'default dev eth(n)'
docker network create -d ipvlan  \
         --subnet=192.168.55.0/24  \
         --gateway=192.168.55.254  \
         -o host_iface=eth1.55 ipnet55
         
### Network w/explicit mode set
docker network create -d ipvlan  \
         --subnet=192.168.56.0/24  \
         -o host_iface=eth1.56  \
         -o ipvlan_mode=l3 ipnet56
         
### Gateway is always ignored in L3 mode - default is 'default dev eth(n)'
docker network create -d ipvlan  \
         --subnet=192.168.57.0/24  \
         --gateway=192.168.57.254  \
         -o host_iface=eth1.57  \
         -o ipvlan_mode=l3 ipnet57
         
### Network w/ explicit mode specified
docker network create -d ipvlan  \
         --subnet=192.168.58.0/24  \
         -o host_iface=eth1.58  \
         -o ipvlan_mode=l3 ipnet58
         
### Network w/ explicit mode specified
docker network create -d ipvlan  \
         --subnet=192.168.59.0/24  \
         -o host_iface=eth1.59  \
         -o ipvlan_mode=l3 ipnet59
         
### Start containers on each network
docker run --net=ipnet53 --name=ipnet53_test -itd alpine /bin/sh
docker run --net=ipnet54 --name=ipnet54_test -itd alpine /bin/sh
docker run --net=ipnet55 --name=ipnet55_test -itd alpine /bin/sh
docker run --net=ipnet56 --name=ipnet56_test -itd alpine /bin/sh
### Start containers with explicit --ip4 addrs
docker run --net=ipnet57 --name=ipnet57_test --ip=192.168.57.10 -itd alpine /bin/sh
docker run --net=ipnet58 --name=ipnet58_test --ip=192.168.58.10 -itd alpine /bin/sh
docker run --net=ipnet59 --name=ipnet59_test --ip=192.168.59.10 -itd alpine /bin/sh
############################################################################################
# Macvlan Multi-Subnet 802.1q VLAN Tagged Bridge Mode Tests
#
#
### Create multiple bridge subnets with a gateway of x.x.x.1:
docker network create -d macvlan  \
         --subnet=192.168.64.0/24 --subnet=192.168.66.0/24  \
         --gateway=192.168.64.1 --gateway=192.168.66.1  \
         -o host_iface=eth0.64  \
         -o macvlan_mode=bridge macnet64
         
### Create multiple bridge subnets with a gateway of x.x.x.254:
docker network create -d macvlan  \
         --subnet=192.168.65.0/24 --subnet=192.168.67.0/24  \
         --gateway=192.168.65.254 --gateway=192.168.67.254  \
         -o host_iface=eth0.65  \
         -o macvlan_mode=bridge macnet65
         
### Create multiple bridge subnets without a gateway (libnetwork IPAM will default to x.x.x.1):
docker network create -d macvlan  \
         --subnet=192.168.70.0/24 --subnet=192.168.72.0/24  \
         -o host_iface=eth0.70  \
         -o macvlan_mode=bridge macnet70
         
# Start Containers on network macnet64
docker run --net=macnet64 --name=macnet64_test --ip=192.168.64.10 -itd alpine /bin/sh
docker run --net=macnet64 --name=macnet66_test --ip=192.168.66.10 -itd alpine /bin/sh
docker run --net=macnet64 --ip=192.168.64.11 -itd alpine /bin/sh
docker run --net=macnet64 --ip=192.168.66.11 -itd alpine /bin/sh
docker run --net=macnet64 -itd alpine /bin/sh

# Start Containers on network macnet65
    docker run --net=macnet65 --name=macnet65_test --ip=192.168.65.10 -itd alpine /bin/sh
    docker run --net=macnet65 --name=macnet67_test --ip=192.168.67.10 -itd alpine /bin/sh
    docker run --net=macnet65 --ip=192.168.65.11 -itd alpine /bin/sh
    docker run --net=macnet65 --ip=192.168.67.11 -itd alpine /bin/sh
    docker run --net=macnet65 -itd alpine /bin/sh
    
# Start Containers on  network macnet70
    docker run --net=macnet70 --name=macnet170_test --ip=192.168.70.10 -itd alpine /bin/sh
    docker run --net=macnet70 --name=macnet172_test --ip=192.168.72.10 -itd alpine /bin/sh
    docker run --net=macnet70 --ip=192.168.70.11 -itd alpine /bin/sh
    docker run --net=macnet70 --ip=192.168.72.11 -itd alpine /bin/sh
    docker run --net=macnet70 -itd alpine /bin/sh
############################################################################################
# Ipvlan Multi-Subnet 802.1q VLAN Tagged L3 Mode Tests
#
#
### Create multiple l3 mode subnets VLAN ID:104 (Gateway is ignored since L3 is always 'default dev eth0'):
docker network create -d ipvlan  \
         --subnet=192.168.104.0/24 --subnet=192.168.106.0/24  \
         --gateway=192.168.104.1 --gateway=192.168.106.1  \
         -o ipvlan_mode=l3  \
         -o host_iface=eth0.104 ipnet104
         
### Create multiple l3 subnets w/ VLAN ID:104:
docker network create -d ipvlan  \
         --subnet=192.168.105.0/24 --subnet=192.168.107.0/24  \
         -o host_iface=eth0.105  \
         -o ipvlan_mode=l3 ipnet105
         
### Create multiple l3 subnets w/ VLAN ID:110:
docker network create -d ipvlan  \
         --subnet=192.168.110.0/24 --subnet=192.168.112.0/24  \
         -o host_iface=eth0.110  \
         -o ipvlan_mode=l3 ipnet110
         
# Start Containers on the network ipnet104
docker run --net=ipnet104 --name=ipnet104_test --ip=192.168.104.10 -itd alpine /bin/sh
docker run --net=ipnet104 --name=ipnet106_test --ip=192.168.106.10 -itd alpine /bin/sh
docker run --net=ipnet104 --ip=192.168.104.11 -itd alpine /bin/sh
docker run --net=ipnet104 --ip=192.168.106.11 -itd alpine /bin/sh
docker run --net=ipnet104 -itd alpine /bin/sh
# Start Containers on the network ipnet105
docker run --net=ipnet105 --name=ipnet105_test --ip=192.168.105.10 -itd alpine /bin/sh
docker run --net=ipnet105 --name=ipnet107_test --ip=192.168.107.10 -itd alpine /bin/sh
docker run --net=ipnet105 --ip=192.168.105.11 -itd alpine /bin/sh
docker run --net=ipnet105 --ip=192.168.107.11 -itd alpine /bin/sh
docker run --net=ipnet105 -itd alpine /bin/sh
# Start Containers on the network ipnet110
docker run --net=ipnet110 --name=ipnet110_test --ip=192.168.110.10 -itd alpine /bin/sh
docker run --net=ipnet110 --name=ipnet112_test --ip=192.168.112.10 -itd alpine /bin/sh
docker run --net=ipnet110 --ip=192.168.110.11 -itd alpine /bin/sh
docker run --net=ipnet110 --ip=192.168.112.11 -itd alpine /bin/sh
docker run --net=ipnet110 -itd alpine /bin/sh
############################################################################################
# Macvlan Bridge Mode V4/V6 Dual Stack Tests
#
#
### Create multiple ipv4 bridge subnets along with a ipv6 subnet
### Note ipv6 requires an explicit --gateway= in this case fe99::10
docker network create -d macvlan  \
         --subnet=192.168.216.0/24 --subnet=192.168.218.0/24  \
         --gateway=192.168.216.1 --gateway=192.168.218.1  \
         --subnet=fe99::/64 --gateway=fe99::10  \
         -o host_iface=eth0.218  \
         -o macvlan_mode=bridge macnet216

docker run --net=macnet216 --name=macnet216_test -itd debian
docker run --net=macnet216 --name=macnet218_test -itd debian
docker run --net=macnet216 --ip=192.168.216.11 -itd debian
docker run --net=macnet216 --ip=192.168.218.11 -itd debian
############################################################################################
# Ipvlan Ipvlan L2 Mode V4/V6 Dual Stack Tests
#
#
### Create multiple ipv4 bridge subnets along with a ipv6 subnet
### Note ipv6 requires an explicit --gateway= in this case fe99::10
docker network create -d ipvlan  \
         --subnet=192.168.213.0/24 --subnet=192.168.215.0/24  \
         --gateway=192.168.213.1 --gateway=192.168.215.1  \
         --subnet=fe97::/64 --gateway=fe97::10  \
         -o host_iface=eth0.213  \
         -o macvlan_mode=bridge ipnet213
         
    docker run --net=ipnet213 --name=ipnet213_test -itd debian
    docker run --net=ipnet213 --name=ipnet215_test -itd debian
    docker run --net=ipnet213 --ip=192.168.213.11 -itd debian
    docker run --net=ipnet213 --ip=192.168.215.11 -itd debian
############################################################################################
# Ipvlan L2 Mode V4/V6 Dual Stack Tests
#
#
# Create an IPv6+IPv4 Dual Stack Ipvlan L3 network
# Gateways for both v4 and v6 are set to a dev e.g. 'default dev eth0'
docker network create -d ipvlan  \
         --subnet=192.168.131.0/24 --subnet=192.168.133.0/24  \
         --subnet=fe94::/64  \
         -o host_iface=eth0.131  \
         -o ipvlan_mode=l3 ipnet131
         
# Start a container on the network
# I use Debian here because how busybox iproute2 handles unreachable network output is funky
    docker run --net=ipnet131 -itd debian
    docker run --net=ipnet131 --ip6=fe94::10 -itd debian
# Create an IPv6+IPv4 Dual Stack Ipvlan L3 network. Same example but verifying the --gateway= are ignored
# Gateway/Nexthop is ignored in L3 mode and eth0 is used instead 'default dev eth0'
docker network create -d ipvlan  \
         --subnet=192.168.119.0/24 --subnet=192.168.117.0/24  \
         --gateway=192.168.119.1 --gateway=192.168.117.1  \
         --subnet=fe96::/64 --gateway=fe96::27  \
         -o host_iface=eth0.117  \
         -o ipvlan_mode=l3 ipnet117
         
# Start a container on the network
# I use Debian here because how busybox iproute2 handles unreachable network output is fudocker run --net=ipnet117 -itd debian
# Start a second container specifying the v6 address
docker run --net=ipnet117 --ip6=fe96::10 -itd debian
# Start a third specifying the IPv4 address
docker run --net=ipnet117 --ip=192.168.117.50 -itd debian
# Start a 4th specifying both the IPv4 and IPv6 addresses
docker run --net=ipnet117 --ip6=fe96::50 --ip=192.168.119.50 -itd debian
############################################################################################
# Macvlan Option Tests
#
#
### macvlan default bridge mode yes, gateway no
docker network create -d macvlan --subnet=192.168.111.0/24 -o host_iface=eth0.111 macvlan111
docker run --net=macvlan111 --ip=192.168.111.10 -it --rm alpine /bin/sh


### macvlan default bridge mode no, gateway no
docker network create -d macvlan --subnet=192.168.112.0/24 -o host_iface=eth0.112 -o macvlan_mode=bridge macvlan112
docker run --net=macvlan112 --ip=192.168.112.10 -it --rm alpine /bin/sh


### macvlan default mode yes, gateway yes
docker network create -d macvlan --subnet=192.168.113.0/24  --gateway=192.168.113.2 -o host_iface=eth0.13 macvlan113
docker run --net=macvlan113 --ip=192.168.113.10 -it --rm alpine /bin/sh


### macvlan default mode no, gateway yes
docker network create -d macvlan --subnet=192.168.114.0/24  --gateway=192.168.114.1 -o host_iface=eth0.14 -o macvlan_mode=bridge macvlan114
docker run --net=macvlan114 --ip=192.168.114.10 -it --rm alpine /bin/sh


### macvlan default mode no, gateway yes
docker network create -d macvlan --subnet=192.168.114.0/24  --gateway=192.168.114.1 -o host_iface=eth0.14 -o macvlan_mode=bridge macvlan114
docker run --net=macvlan114 --ip=192.168.114.10 -it --rm alpine /bin/sh
### Ensure eth0.116 was not deleted since it existed prior to the network creation


############################################################################################
# IpVlan Option Tests
#
#
### ipvlan default bridge mode yes, gateway no
docker network create -d ipvlan --subnet=192.168.11.0/24 -o host_iface=eth0.111 ipvlan11
docker run --net=ipvlan11 --ip=192.168.11.10 -it --rm alpine /bin/sh


### ipvlan default bridge mode no, gateway no
docker network create -d ipvlan --subnet=192.168.12.0/24 -o host_iface=eth0.112 -o ipvlan_mode=bridge ipvlan12
docker run --net=ipvlan12 --ip=192.168.12.10 -it --rm alpine /bin/sh


### ipvlan default mode yes, gateway yes
docker network create -d ipvlan --subnet=192.168.13.0/24  --gateway=192.168.13.2 -o host_iface=eth0.13 ipvlan13
docker run --net=ipvlan13 --ip=192.168.13.10 -it --rm alpine /bin/sh


### ipvlan default mode no, gateway yes
docker network create -d ipvlan --subnet=192.168.14.0/24  --gateway=192.168.14.1 -o host_iface=eth0.14 -o ipvlan_mode=bridge ipvlan14
docker run --net=ipvlan14 --ip=192.168.14.10 -it --rm alpine /bin/sh


### ipvlan default mode no, gateway yes
docker network create -d ipvlan --subnet=192.168.14.0/24  --gateway=192.168.14.1 -o host_iface=eth0.14 -o ipvlan_mode=bridge ipvlan14
docker run --net=ipvlan14 --ip=192.168.14.10 -it --rm alpine /bin/sh
### Ensure eth0.116 was not deleted since it existed prior to the network creation


############################################################################################
# MacVlan Manual 802.1q Trunk Tests (if the ip link exists prior to network creation, it should not be deleted)
#
#
### Manually create ip link sub interface and ensure it works as a passed host_iface=X
ip link add link eth0 name eth0.foomac type vlan id 115
docker network create -d macvlan --subnet=192.168.115.0/24 --gateway=192.168.115.1 -o host_iface=eth0.foo macvlanfoo
docker run --net=macvlanfoo -it --rm alpine /bin/sh
docker network rm macvlanfoo
### Ensure the link eth0.foomac was not deleted


### Manually create ip link sub interface and ensure it works as a passed host_iface=X
ip link add link eth0 name eth0.foomac type vlan id 115
docker network create -d macvlan --subnet=192.168.115.0/24 --gateway=192.168.115.1 -o host_iface=eth0.foo macvlanfoo
docker run --net=macvlanfoo -it --rm alpine /bin/sh
docker network rm macvlanfoo
### Ensure the link eth0.foomac was not deleted


### Manually create ip link sub interface and ensure it works as a passed host_iface=X
ip link add link eth0 name eth0.116 type vlan id 116
docker network create -d macvlan --subnet=192.168.116.0/24 --gateway=192.168.116.1 -o host_iface= eth0.116 macvlan116
docker run --net= macvlan116 -it --rm alpine /bin/sh
docker network rm macvlan116
### Ensure the link eth0.116 was not deleted


### Cleanup all containers
docker rm  -f `docker ps -qa`

### Delete all networks and ensure the ip links are cleaned up
docker network rm $(docker network ls | grep ipvlan | awk '{print $1}')

### Delete the link that should still exist, since they were not created by the driver, but manually.
ip link del foomac
ip link del eth0.116


############################################################################################
# Ipvlan Manual Trunk Tests (if the ip link exists prior to network creation, it should not be deleted)
#
#
### Manually create ip link sub interface and ensure it works as a passed host_iface=X
ip link add link eth0 name eth0.fooipv type vlan id 115

docker network create -d ipvlan \
    --subnet=192.168.15.0/24 \
    --gateway=192.168.15.1 \
    -o host_iface=eth0.foo ipvlanfoo

docker run --net=ipvlanfoo -it --rm alpine /bin/sh
docker network rm ipvlanfoo

### Ensure the link eth0.fooipv was not deleted
ip link show ipvlanfoo

### Manually create ip link sub interface and ensure it works as a passed host_iface=X
ip link add link eth0 name eth0.fooipv type vlan id 115

docker network create -d ipvlan \
    --subnet=192.168.15.0/24 \
    --gateway=192.168.15.1 \
    -o host_iface=eth0.foo ipvlanfoo

docker run --net=ipvlanfoo -it --rm alpine /bin/sh
docker network rm ipvlanfoo

### Ensure the link eth0.fooipv was not deleted
ip link show eth0.fooipv

### Manually create ip link sub interface and ensure it works as a passed host_iface=X
ip link add link eth0 name eth0.116 type vlan id 116
docker network create -d ipvlan \
    --subnet=192.168.16.0/24 \
    --gateway=192.168.16.1 \
    -o host_iface= eth0.116 ipvlan16

docker run --net= ipvlan16 -it --rm alpine /bin/sh
docker network rm ipvlan16

### Ensure the link eth0.116 was not deleted
ip link show ipvlan16

### Cleanup all containers
docker rm  -f `docker ps -qa`

### Delete all networks and ensure the ip links are cleaned up
docker network rm $(docker network ls | grep ipvlan | awk '{print $1}')

### Delete the link that should still exist, since they were not created by the driver, but manually.
ip link del fooipv
ip link del eth0.116


############################################################################################
# Macvlan tests that SHOULD Fail
#
#
### Macvlan bad subinterface test
docker network create -d macvlan --subnet=192.168.70.0/24 -o host_iface=eth0:70 -o ipvlan_mode=bridge macnet70

### Macvlan bad subinterface test
docker network create -d macvlan --subnet=192.168.70.0/24 -o host_iface=eth0:71  macnet71

### Macvlan bad mode test
docker network create -d ipvlan --subnet=192.168.71.0/24 -o host_iface=eth0.71 -o ipvlan_mode=l2 macnet71

### Overlapping parent interfaces
docker network create -d macvlan --subnet=192.168.55.0/24 -o host_iface=eth0.55 -o macvlan_mode=bridge macnet55
docker network create -d macvlan --subnet=192.168.59.0/24 -o host_iface=eth0.55 -o macvlan_mode=bridge macnet59

# Create an IPv6 Macvlan network with mismatched subnet/gateway
docker network create -d macvlan --subnet=fe93::/64 --gateway=fe90::22 -o host_iface=eth0.131 v6macvlan131

### Macvlan vlan upper bounds violation
docker network create -d macvlan --subnet=192.168.84.0/24 -o host_iface=eth0.8400 --internal -o macvlan_mode=bridge macnet84

### Macvlan vlan lower bounds violation
docker network create -d macvlan --subnet=192.168.84.0/24 -o host_iface=eth0.0 -o macvlan_mode=bridge macnet84

# Create a network without a '-o host_iface'
docker network create -d macvlan --subnet=192.168.83.0/24 -o macvlan_mode=l2 macvlan83

############################################################################################
# Ipvlan L2 tests that SHOULD Fail
#
#
### Ipvlan bad subinterface test
docker network create -d ipvlan --subnet=192.168.80.0/24 -o host_iface=eth0:80 -o ipvlan_mode=l3 ipnet80

### Ipvlan bad subinterface test
docker network create -d ipvlan --subnet=192.168.81.0/24 -o host_iface=eth0:81 ipnet81

### Ipvlan bad mode test
docker network create -d ipvlan --subnet=192.168.82.0/24 -o host_iface=eth0.82 -o ipvlan_mode=bridge ipnet81

### Macvlan invalid --internal option
docker network create -d macvlan --subnet=192.168.84.0/24 -o host_iface=eth0.84 --internal -o ipvlan_mode=l2 ipnet84

### Macvlan vlan upper bounds violation
docker network create -d macvlan --subnet=192.168.84.0/24 -o host_iface=eth0.8400 --internal -o ipvlan_mode=l2 ipnet84

### Macvlan vlan lower bounds violation
docker network create -d macvlan --subnet=192.168.84.0/24 -o host_iface=eth0.0 -o ipvlan_mode=l2 ipnet84

### Macvlan Port Mappings should Fail
docker network create -d ipvlan --subnet=192.168.85.0/24 -o host_iface=eth0.85 -o ipvlan_mode=l2 ipnet85
docker run --net=ipnet85 -p 80:80  -it --rm alpine /bin/sh
docker run --net=ipnet85 -p 80:80  -it --rm alpine /bin/sh


### Macvlan 802.1q VID upper bound violation
docker network create -d ipvlan --subnet=192.168.111.0/24 -o host_iface=eth0.4095 -o ipvlan_mode=l2 ipnet111

### Macvlan 802.1q VID lower bound violation
docker network create -d ipvlan --subnet=192.168.112.0/24 -o host_iface=eth0.0 -o ipvlan_mode=l2 ipnet112

### Overlapping parent interfaces
docker network create -d ipvlan --subnet=192.168.57.0/24 -o host_iface=eth0.57 -o ipvlan_mode=l2 ipnet57
docker network create -d ipvlan --subnet=192.168.58.0/24 -o host_iface=eth0.57 -o ipvlan_mode=l2 ipnet58

# Create an IPv6 Ipvlan network with mismatched subnet/gateway
docker network create -d ipvlan --subnet=fe93::/64 --gateway=fe90::22 -o host_iface=eth0.137 v6ipvlan137

# Create a network without a '-o host_iface'
docker network create -d ipvlan --subnet=192.168.83.0/24 -o ipvlan_mode=l2 ipnet83


############################################################################################
# Ipvlan L3 tests that SHOULD Fail
#
#
### Ipvlan bad subinterface test
docker network create -d ipvlan --subnet=192.168.60.0/24 -o host_iface=eth0:60 -o ipvlan_mode=l3 ipnet60

### Ipvlan bad subinterface test
docker network create -d ipvlan --subnet=192.168.61.0/24 -o host_iface=eth0:61 -o ipvlan_mode=foo ipnet61

### Ipvlan bad mode test
docker network create -d ipvlan --subnet=192.168.62.0/24 -o host_iface=eth0.62 -o ipvlan_mode=bridge ipnet62

### Ipvlan invalid --internal option
docker network create -d ipvlan --subnet=192.168.63.0/24 -o host_iface=eth0.63 --internal -o ipvlan_mode=l2 ipnet63

### Overlapping parent interfaces (2nd network should fail)
docker network create -d ipvlan --subnet=192.168.58.0/24 -o host_iface=eth0.58 -o ipvlan_mode=l3 ipnet58
docker network create -d ipvlan --subnet=192.168.59.0/24 -o host_iface=eth0.58 -o ipvlan_mode=l3 ipnet59


############################################################################################
# Miscellaneous
#
#
### Delete all macvlan driver networks
docker network rm $(docker network ls | grep macvlan | awk '{print $1}')

### Delete all ipvlan driver networks
docker network rm $(docker network ls | grep ipvlan | awk '{print $1}')

### Delete all containers
docker rm  -f `docker ps -qa`