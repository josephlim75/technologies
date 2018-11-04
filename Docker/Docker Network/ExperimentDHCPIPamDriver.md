# Experimental Docker Libnetwork DHCP Driver

https://gist.github.com/nerdalert/3d2b891d41e0fa8d688c

The DHCP driver is intended for users to be able to integrate Docker IP address management  with their existing IPAM strategies that use DHCP for dynamic address assignment. DHCP enables users to allocate addresses in an organized fashion that will prevent overlapping IP address assignment by associating a unique MAC address from the container `eth0` Ethernet interface to an IP address as determined by the DHCP pools defined in the DHCP configuration.

This driver only provides the DHCP client functionality. It does not include a DHCP server. The default driver offers single-host IPAM or for distributed multi-host orchestrated IPAM see the libnetwork overlay driver.

### Getting Started

- Download the driver compiled into Docker Engine - [docker binary with libnetwork test dhcp client spam driver](https://github.com/nerdalert/docker-scripts/files/190827/docker-dev-1.11-dhcp-driver-linux-bin.zip)

- Or pull the branch at [github.com/nerdalert/libnetwork/tree/dhcp_client](https://github.com/nerdalert/libnetwork/tree/dhcp_client). This branch does not include any timer code (e.g. goroutines tracking lease state, its for exploration only).

- More information about the DHCP wire protocol at [DHCP RFC 2131](https://www.ietf.org/rfc/rfc2131.txt)

### Example DHCP Driver Client Usages

By default, the DHCP client driver will automatically probe for a network that `eth0` is attached to by using a `DHCP DISCOVER` broadcast. If there is a DHCP server on the broadcast domain or handled by a relay/helper agent the existing DHCP server will reply with details about the available network that exists. The driver will then create the Docker IPAM pool and network for the user using the discovered information. From there, a user needs to simply start containers and receive IP addresses from the DHCP server. 

The DHCP driver creates the DHCP requests using the MAC address of the container. The DHCP server will keep track of available addresses in the pool to ensure there are no overlapping addresses for all of the different Docker hosts running on the same Ethernet segment. Users can leverage their DHCP server of choice and monitor address allocations of all containers from the DHCP server's interface. When containers are removed `docker rm <container_id>`, the DHCP client driver sends a DHCP release out the specified `--ipam-opt dhcp_interface=<host interface>` and returns the IP address back to the DHCP server's address pool.

**Note:** If running Docker nested in a hypervisor, the VM's NIC needs to be in **promiscous** mode just as it would if you were running a nested hypervisor. This means the host Ethernet device can look at traffic with destination MAC addresseses that are different from its own MAC address. Since the DHCP client driver will be sending DHCP requests on behalf of the MAC address of a container, the host needs to be able to process those packets with differing MAC addresses. Along with various DHCP troubleshooting tools for Linux that are generally available, tcpdump can be used to troubleshoot filtering on the relevant UDP ports `sudo tcpdump -i eth0 -n udp -v portrange 67-68`. Tcpdump on a production network can be extremely chatty so use with care if not experienced with troubleshooting network issues.

- The following example discovers both the subnet and gateway of the host. It does **not** discover any other DHCP options such as DNS or any other fields that are plumbed into the container. Any other options discovered are used by the driver in order to provide an easy network environment to manage.

```
# Create a network using eth0 as the parent and interface to discover what subnet to use for the network eth0 is attached
docker network create -d macvlan \
  --ipam-driver=dhcp \
  -o parent=eth0 \
  --ipam-opt dhcp_interface=eth0 mcv0

# When containers are created, DHCP requests will assign an IP addresses to each container
docker run --net=mcv0 -itd alpine /bin/sh
docker run --net=mcv0 -itd alpine /bin/sh

# When the containers are destroyed, the DHCP client driver sends a DHCP release and returns the IP address back to the DHCP servers address pool
docker rm -f `docker ps -qa`
docker network rm mcv0
```

Users can also explicitly specify the network's address pool `--subnet=` and `--gateway=` rather then the DHCP client driver discovering the subnet for them. Either way, when the containers are started, DHCP requests are sent by the driver when containers are started. The specified `--subnet` **must** match the subnet the DHCP server is handing out or else the driver will prevent a container creation (`docker run`) since the network and containers on the network need to coincide.

```
docker network create -d macvlan \
  --ipam-driver=dhcp \
  --subnet=172.16.86.0/24 \
  --gateway=172.16.86.2 \
  -o parent=eth0 \
  --ipam-opt dhcp_interface=eth0 mcv0

docker run --net=mcv0 -itd alpine /bin/sh
docker run --net=mcv0 -itd alpine /bin/sh

docker rm -f `docker ps -qa`
docker network rm mcv0
```

- If a gateway is not specified, the driver will infer the gateway by using the first usable address on the user specified `--subnet`.

```
docker network create -d macvlan \
  --ipam-driver=dhcp \
  --subnet=172.16.86.0/24 \
  -o parent=eth0 \
  --ipam-opt dhcp_interface=eth1 mcv0

docker run --net=mcv0 -itd alpine /bin/sh
docker run --net=mcv0 -itd alpine /bin/sh
```

### VLAN Tagged Networks

- Just as sub-interfaces tagged with VLAN IDs get dynamically created with the `macvlan` driver, this will also work in conjunction with the DHCP IPAM driver. Since Spanning-Tree will block links during STP convergence for up to 50 seconds, the `--network` and `--gateway` need to be specified by the user when creating the network using the standard `docker network create` command.

- Once the new sub-interface is forwarding, containers started on that network will receive their IPv4 addresses from the DHCP server.

- As with the `macvlan` driver, an existing interface can be passed and used, rather then the driver creating the sub-interface. If libnetwork drivers create a sub-interface, it will also delete them on `docker network delete` and rebuild them upon server reboot or Docker engine reboot from persistent storage offered by libnetwork. If the driver did not create the link but is passed an existing link, it will never delete that link, deletes will only occur if the driver created the link.


The following example will create a sub-interface tagged with `VLAN 10` and create a network pool of usable addresses on the `172.16.86.0/24` network. The corresponding address pool on the DHCP server that is providing address on `VLAN 10` will need to offer addresses on the `172.16.86.0/24` network.

```
docker network create -d macvlan \
  --ipam-driver=dhcp \
  --subnet=172.16.86.0/24 \
  --gateway=172.16.86.2 \
  -o parent=eth0.10 \
  --ipam-opt dhcp_interface=eth1.10 mcv0

docker network rm mcv0
```
If a network create is attempted with a sub-inerface, it will be rejected like the following example. It is merely because VLAN tagged links going to a Linux server will almost always block while Spanning-Tree converges since RSTP (Rapid Spanning-Tree) is primarily reserved for network switches with more advanced Layer2 implementations then Linux.

```
$ docker network create -d macvlan --ipam-driver=dhcp -o parent=eth0.10 --ipam-opt dhcp_interface=eth0.10 mcv0
Error response from daemon: Spanning-Tree convergence can block forwarding and thus DHCP for up to 50 seconds. If creating VLAN subinterfaces, --gateway and --subnet are required in 'docker network create'.
```

Same as if a sub-interface is not used, if a gateway is not passed, the driver will infer the gateway by using the first usable address from the `--subnet` passed in the network create. The following will get a gateway address of `172.16.86.1`

```
docker network create -d macvlan \
  --ipam-driver=dhcp \
  --subnet=172.16.86.0/24 \
  -o parent=eth0.10 \
  --ipam-opt dhcp_interface=eth1.10 mcv0

docker rm -f `docker ps -qa`
docker network rm mcv0
```

### Driver TODOs

- What to do with DNS and Domain options from DHCP server?
- Verify or add functionality with Bridge driver.
- Opt code 12 (hostname) needs to be included in the `DHCP REQUEST` for added management value to see meaningful hostname/MAC/IP address mappings in the users DHCP server.  