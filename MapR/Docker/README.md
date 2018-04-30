## Docker Steps

- Get from centos/systemd images
- Run to remove unwanted systemd unit
  ```
	FROM centos:centos7

	#Fix incompatibility between Docker and systemd
	#copy/paste from https://forums.docker.com/t/systemctl-status-is-not-working-in-my-docker-container/9075/4
	#additional steps from https://github.com/CentOS/sig-cloud-instance-images/issues/41
  
	RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
	     rm -f /lib/systemd/system/multi-user.target.wants/*; \
	     rm -f /etc/systemd/system/*.wants/*; \
	     rm -f /lib/systemd/system/local-fs.target.wants/*; \
	     rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
	     rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
	     rm -f /lib/systemd/system/basic.target.wants/*; \
	     rm -f /lib/systemd/system/anaconda.target.wants/*; \
	     mkdir -p /etc/selinux/targeted/contexts/ &&\
	     echo '<busconfig><selinux></selinux></busconfig>' > /etc/selinux/targeted/contexts/dbus_contexts

	VOLUME [ "/sys/fs/cgroup" ]
	CMD ["/usr/lib/systemd/systemd"]
	ENV TERM=xterm
```
## Alternative Systemd container

```
	FROM centos:centos7
	MAINTAINER Marcel Wysocki "maci.stgn@gmail.com"
	ENV container docker

	RUN yum -y update; yum clean all

	RUN yum -y swap -- remove systemd-container systemd-container-libs -- install systemd systemd-libs dbus

	RUN systemctl mask dev-mqueue.mount dev-hugepages.mount \
		systemd-remount-fs.service sys-kernel-config.mount \
		sys-kernel-debug.mount sys-fs-fuse-connections.mount \
		display-manager.service graphical.target systemd-logind.service

	ADD dbus.service /etc/systemd/system/dbus.service
	RUN systemctl enable dbus.service

	#RUN yum -y install passwd; yum clean all
	#RUN echo root | passwd --stdin root

	#RUN yum -y install openssh-server initscripts; yum clean all
	#RUN echo "UseDNS no" >> /etc/ssh/sshd_config
	#RUN sed -i 's/UsePrivilegeSeparation sandbox/UsePrivilegeSeparation no/' /etc/ssh/sshd_config

	VOLUME ["/sys/fs/cgroup"]
	VOLUME ["/run"]

	CMD  ["/usr/lib/systemd/systemd"]
```

## Remove /etc/init.d/network

### Docker Mapr Init script /usr/bin/init-script

```
	#/bin/bash

	service sshd start

	IP=$(ip addr show eth0 | grep -w inet | awk '{ print $2}' | cut -d "/" -f1)

	echo -e "${IP}\t$(hostname -f).mapr.io\t$(hostname)" >> /etc/hosts
	echo -e "${CLDBIP}\t${CLUSTERNAME}c1.mapr.io\t${CLUSTERNAME}c1 " >> /etc/hosts

	#fallocate -l 20G /opt/mapr/docker.disk
	#dd if=/dev/zero of=/opt/mapr/docker.disk bs=1G count=20

	/opt/mapr/server/mruuidgen > /opt/mapr/hostid
	cat /opt/mapr/hostid > /opt/mapr/conf/hostid.$$

	cp /proc/meminfo /opt/mapr/conf/meminfofake

	sed -i "/^MemTotal/ s/^.*$/MemTotal:     ${MEMTOTAL} kB/" /opt/mapr/conf/meminfofake
	sed -i "/^MemFree/ s/^.*$/MemFree:     ${MEMTOTAL-10} kB/" /opt/mapr/conf/meminfofake
	sed -i "/^MemAvailable/ s/^.*$/MemAvailable:     ${MEMTOTAL-10} kB/" /opt/mapr/conf/meminfofake

	sed -i 's/AddUdevRules(list/#AddUdevRules(list/' /opt/mapr/server/disksetup

	#sed -i 's/isDB=true/isDB=false/' /opt/mapr/conf/warden.conf
	#sed -i 's/service.command.mfs.heapsize.percent=.*/service.command.mfs.heapsize.percent=8/' /opt/mapr/conf/warden.conf
	#sed -i 's/service.command.mfs.heapsize.maxpercent=.*/service.command.mfs.heapsize.maxpercent=8/' /opt/mapr/conf/warden.conf

	#/opt/mapr/server/configure.sh -C ${CLDBIP} -Z ${CLDBIP} -N docker-demo-cluster.mapr.com -RM ${CLDBIP} -u mapr -D ${DISKLIST} -noDB
	/opt/mapr/server/configure.sh -C ${CLDBIP} -Z ${CLDBIP} -D ${DISKLIST} -N ${CLUSTERNAME}.mapr.io -u mapr -g mapr -noDB -RM ${CLDBIP}


	echo "This container IP : ${IP}"

	#/bin/bash

	while true
	do
	sleep 5
	done
```

## MapR Repository
```
	[maprtech]
	name=MapR Technologies
	baseurl=http://package.mapr.com/releases/v6.0.1/redhat/
	enabled=1
	gpgcheck=0
	protect=1

	[maprecosystem]
	name=MapR Technologies
	baseurl=http://package.mapr.com/releases/MEP/MEP-5.0.0/redhat
	enabled=1
	gpgcheck=0
	protect=1
```

## Docker Command

```
	yum install -y mapr-zookeeper mapr-cldb mapr-fileserver mapr-resourcemanager mapr-nodemanager mapr-apiserver mapr-historyserver

	strings libstdc++.so.6|grep GLIBC	
		
	groupadd -g 5000 mapr; \
	useradd -g 5000 -u 5000 mapr; \
	echo mapr:mapr|chpasswd


	yum install -y mapr-zookeeper mapr-cldb mapr-historyserver mapr-webserver mapr-resourcemanager mapr-nodemanager

	maprcli  disk add -disks /dev/sdx -host 127.0.0.1
		
	docker run --rm -ti --cap-add SYS_ADMIN --cap-add SYS_RESOURCE  -p 8080:8080 -p 8443:8443 -h cluster1.argusnet --net argusnet --device /dev/sdb1 -v /sys/fs/cgroup:/sys/fs/cgroup:ro josephlim75/mapr-control:1.2.0-centos7-346201740698902345 bash
	/opt/mapr/server/configure.sh -C cluster1.argusnet:7222 -Z cluster1.argusnet:5181 -HS cluster1.argusnet -N cluster1  --isvm
	export MAPR_SUBNETS=10.0.1.0/24

	docker run --rm -ti --cap-add SYS_ADMIN --cap-add SYS_RESOURCE  -p 3306:3306 -p 8080:8080 -p 8443:8443 -h cluster2.argusnet --net argusnet --device /dev/sdb1 -v /sys/fs/cgroup:/sys/fs/cgroup:ro josephlim75/mapr-control:1.1.0-hive bash
	/opt/mapr/server/configure.sh -C cluster2.argusnet:7222 -Z cluster2.argusnet:5181 -HS cluster2.argusnet -N cluster2  --isvm
	export MAPR_SUBNETS=10.0.1.0/24
	mysql root/joseph6728


	docker run --rm -ti --privileged --cap-add SYS_ADMIN -p 8080:8080 -p 8443:8443 -h cluster3.macvlan --net macvlan -v /sys/fs/cgroup:/sys/fs/cgroup:ro tedp-mapr-control:1.4.0
	/opt/mapr/server/configure.sh -C cluster3:7222 -Z cluster3:5181 -HS cluster3 -N cluster3  --isvm


	CREATE EXTERNAL TABLE text_tab (
		username string)
	STORED AS TEXTFILE
	LOCATION
	 '/mapr/cluster1/user/mapr/data'

	/opt/mapr/server/disksetup -F /tmp/disks.txt

	maprcli volume list -columns volumename,numreplicas,minreplicas,nsNumReplicas,nsMinReplicas,DataUnderReplicatedAlarm

	maprcli volume modify -name \
		mapr.apps,\
		mapr.cluster.root,mapr.cluster3.macvlan.local.audit,mapr.cluster3.macvlan.local.logs,mapr.cluster3.macvlan.local.mapred,mapr.cluster3.macvlan.local.metrics,mapr.configuration,mapr.metrics,mapr.monitoring,mapr.monitoring.streams,mapr.opt,mapr.resourcemanager.volume,mapr.tmp,mapr.var,users -minreplication 1 -nsminreplication 1 -replication 1 -nsreplication 1

	maprcli volume modify -name mapr.apps,mapr.cldb.internal -minreplication 1 -nsminreplication 1 -replication 1 -nsreplication 1
```
