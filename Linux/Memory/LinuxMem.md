## ERROR
- kernel: SLUB: Unable to allocate memory on node -1 (gfp=0x8020) -- ip6_dst_cache
- kernel: SLUB: Unable to allocate memory on node -1 (gfp=0x20)   -- kmalloc
- JVM crash
- https://bugs.schedmd.com/show_bug.cgi?id=2846

## Troubleshooting

### Command to check
  
    $ sudo dmesg
    $ sudo /var/log/messages
    $ sudo ps -eo user,pid,rss,size,vsize,comm|grep -E 'USER|docker|trans'
    $ cat /proc/meminfo | grep -P "(Dirty|Mapped|DirectMap4k)"


### Check Swap

    $ sudo swap -s        --> Look at swap summary
    $ mkswap -c <device>  --> check for bad blocks
    $ cat /proc/swaps     --> Check swap disk/file
    $ free -h OR free -m
    $ vmstate OR atop OR htop
    
## Explanation

### Explain 1
- https://superuser.com/questions/1317468/what-is-dirty-memory-and-how-to-deal-with-it

'Dirty' memory is memory representing data on disk that has been changed but has not yet been written out to disk. Among other things, it includes:

- Memory containing buffered writes that have not been flushed to disk yet.
- Regions of memory mapped files that have been updated but not written out to disk yet.
- Pages that are in the process of being written to swap space but have changed since the system started writing them to swap space.

Having a few MB of dirty memory is normal on any reasonably busy system, and even spikes up to a few hundred MB are not unusual. The only time to 
really be worried about it is if it's consistently very high, which is usually a sign that your disks are a performance bottleneck for your system.


### Kernel and Docker Bugs

After much debugging, we found that specific combinations of kernel version and Docker version 
create a major problem with memory accounting.  In our case, combining kernel version 3.19 with 
Docker version 1.12 exposed this bug.  We had been running the 3.19 kernel for a long time, and 
it wasn’t immediately obvious that the kernel was a contributing factor to memory issues.
The core of the issue is that Docker 1.12 turns on kmem accounting.  In 3.x versions of the Linux 
kernel, this causes problems because of a slab shrinker issue.  In a nutshell, this causes the 
kernel to think that there is more kernel memory used than there actually is, and it starts killing 
processes to reclaim memory.  Eventually it kills the JVM, which obviously hurts the cluster.  
There is a fix for the slab shrinker issue in kernel versions >= 4.0.  Our testing led us to combine 
kernel version 4.4 with Docker 1.12.  This combination solved the kmem accounting problems.

## Solutions

### Stackoverflow solutions

    net.ipv4.tcp_timestamps = 0 
    net.ipv4.tcp_max_syn_backlog = 4096 
    net.core.somaxconn = 1024 
    net.ipv4.tcp_syncookies = 1 
    net.core.rmem_max = 16777216 
    net.core.wmem_max = 16777216 
    net.core.rmem_default = 65535 
    net.core.wmem_default = 65535 
    net.ipv4.tcp_rmem = 4096 87380 16777216 
    net.ipv4.tcp_wmem = 4096 65536 16777216 
    net.ipv4.ip_local_port_range = 1024 65535 
    vm.max_map_count = 262144 
    vm.swappiness=10 
    vm.vfs_cache_pressure=100

Problems seems to be with kernel, first a fall check whether swap memory is properly allocated or not by free -m and mkswap -c, 
if swap is not properly allocated, do it. if swap is fine, then you might need to update the kernel.    
    
### Stackoverflow solution 2

- https://unix.stackexchange.com/questions/385266/docker-cannot-allocate-memory-virtual-memory-tuning

    vm.admin_reserve_kbytes = 8192
    vm.block_dump = 0
    vm.dirty_background_bytes = 0
    vm.dirty_background_ratio = 10
    vm.dirty_bytes = 0
    vm.dirty_expire_centisecs = 3000
    vm.dirty_ratio = 30
    vm.dirty_writeback_centisecs = 500
    vm.drop_caches = 1
    vm.extfrag_threshold = 500
    vm.hugepages_treat_as_movable = 0
    vm.hugetlb_shm_group = 0
    vm.laptop_mode = 0
    vm.legacy_va_layout = 0
    vm.lowmem_reserve_ratio = 256   256     32
    vm.max_map_count = 65530
    vm.memory_failure_early_kill = 0
    vm.memory_failure_recovery = 1
    vm.min_free_kbytes = 67584
    vm.min_slab_ratio = 5
    vm.min_unmapped_ratio = 1
    vm.mmap_min_addr = 4096
    vm.nr_hugepages = 0
    vm.nr_hugepages_mempolicy = 0
    vm.nr_overcommit_hugepages = 0
    vm.nr_pdflush_threads = 0
    vm.numa_zonelist_order = default
    vm.oom_dump_tasks = 1
    vm.oom_kill_allocating_task = 0
    vm.overcommit_kbytes = 0
    vm.overcommit_memory = 0
    vm.overcommit_ratio = 50
    vm.page-cluster = 3
    vm.panic_on_oom = 0
    vm.percpu_pagelist_fraction = 0
    vm.stat_interval = 1
    vm.swappiness = 30
    vm.user_reserve_kbytes = 108990
    vm.vfs_cache_pressure = 100
    vm.zone_reclaim_mode = 0    
    
### Redhat Solution recommendation

- https://access.redhat.com/solutions/723263


### Workaround 1

- Upgrade kernel to at least 4.9 and higher.  Resolving SLAB / SLUB shrinking issue
- My problem was solved by kernel update to 4.9 version + overlayfs.

### Workaround 2

Using cgmemtime

cgmemtime measures the high-water RSS+CACHE memory usage of a process and its descendant processes.
To be able to do so it puts the process into its own cgroup.


### IPv6 stack freeze caused by full ip6_dst_cache
#### Workaround:
- https://www.novell.com/support/kb/doc.php?id=7018525

Please adjust the following value to prevent the IPv6 destination cache overflow.
    echo 0 > /proc/sys/net/ipv4/tcp_tw_recycle
For reboot persistent settings please edit /etc/sysctl.conf and add:
    net.ipv4.tcp_tw_recycle = 0

#### Resolution: 

Please update to kernel 3.0.101-94.1 or later. The patches involved to address this issue are:
- tcp: fix inet6_csk_route_req() for link-local addresses (bsc#1010175).
- tcp: pass fl6 to inet6_csk_route_req() (bsc#1010175).
- tcp: plug dst leak in tcp_v6_conn_request() (bsc#1010175).
- tcp: use inet6_csk_route_req() in tcp_v6_send_synack() (bsc#1010175).



Sep 11 09:15:09 lepmaprpdn02 kernel:  node 0: slabs: 100, objs: 3249, free: 0
Sep 11 09:15:09 lepmaprpdn02 kernel:  node 1: slabs: 71, objs: 2367, free: 0
Sep 11 09:15:09 lepmaprpdn02 kernel: SLUB: Unable to allocate memory on node -1 (gfp=0x8020)
Sep 11 09:15:09 lepmaprpdn02 kernel:  cache: ip6_dst_cache(399:572c44f89791131ed6320e904f7061a1c87e1a364764cb0b6d84ea8d9e09f75b), object size: 448, buffer size: 448, default order: 2, min order: 0
Sep 11 09:15:09 lepmaprpdn02 kernel:  node 0: slabs: 100, objs: 3249, free: 0
Sep 11 09:15:09 lepmaprpdn02 kernel:  node 1: slabs: 71, objs: 2367, free: 0
Sep 11 09:15:26 lepmaprpdn02 sshd[47241]: error: Could not load host key: /etc/ssh/ssh_host_dsa_key
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=CRYPTO_KEY_USER msg=audit(1536671726.160:355089): pid=47242 uid=0 auid=4294967295 ses=4294967295 msg='op=destroy kind=server fp=SHA256:b0:5a:1f:70:24:e5:f4:64:51:97:af:2b:05:06:e8:dd:2e:b8:f1:53:be:75:de:05:2e:c8:d3:8c:0a:5b:fe:0f direction=? spid=47242 suid=0  exe="/usr/sbin/sshd" hostname=? addr=? terminal=? res=success'
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=CRYPTO_KEY_USER msg=audit(1536671726.160:355090): pid=47242 uid=0 auid=4294967295 ses=4294967295 msg='op=destroy kind=server fp=SHA256:5a:65:88:9d:62:f6:e5:77:45:df:2e:81:14:d6:9b:4a:d9:19:69:6a:51:42:e3:58:a4:66:c6:2a:36:94:0a:ed direction=? spid=47242 suid=0  exe="/usr/sbin/sshd" hostname=? addr=? terminal=? res=success'
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=CRYPTO_KEY_USER msg=audit(1536671726.160:355091): pid=47242 uid=0 auid=4294967295 ses=4294967295 msg='op=destroy kind=server fp=SHA256:7d:24:f2:3d:c6:fe:62:43:21:db:ea:0a:d2:c4:30:29:82:99:50:07:b7:b3:2f:98:60:7d:71:c3:f4:39:cd:8d direction=? spid=47242 suid=0  exe="/usr/sbin/sshd" hostname=? addr=? terminal=? res=success'
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=CRYPTO_SESSION msg=audit(1536671726.162:355092): pid=47241 uid=0 auid=4294967295 ses=4294967295 msg='op=start direction=from-server cipher=aes256-ctr ksize=256 mac=hmac-sha2-256 pfs=diffie-hellman-group-exchange-sha256 spid=47242 suid=74 rport=10207 laddr=10.123.128.25 lport=22  exe="/usr/sbin/sshd" hostname=? addr=172.21.6.210 terminal=? res=success'
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=CRYPTO_SESSION msg=audit(1536671726.162:355093): pid=47241 uid=0 auid=4294967295 ses=4294967295 msg='op=start direction=from-client cipher=aes256-ctr ksize=256 mac=hmac-sha2-256 pfs=diffie-hellman-group-exchange-sha256 spid=47242 suid=74 rport=10207 laddr=10.123.128.25 lport=22  exe="/usr/sbin/sshd" hostname=? addr=172.21.6.210 terminal=? res=success'
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=USER_AUTH msg=audit(1536671726.509:355094): pid=47244 uid=0 auid=4294967295 ses=4294967295 msg='op=PAM:authentication grantors=pam_centrifydc acct="jlim" exe="/usr/sbin/sshd" hostname=172.21.6.210 addr=172.21.6.210 terminal=ssh res=success'
Sep 11 09:15:26 lepmaprpdn02 adclient[13162]: INFO  AUDIT_TRAIL|Centrify Suite|PAM|1.0|100|PAM authentication granted|5|user=jlim(type:ad,JLim@TSYSECOM.ORG) pid=47244 utc=1536671726509 centrifyEventID=24100 status=GRANTED service=sshd tty=ssh client=172.21.6.210
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=USER_ACCT msg=audit(1536671726.510:355095): pid=47244 uid=0 auid=4294967295 ses=4294967295 msg='op=PAM:accounting grantors=pam_centrifydc acct="jlim" exe="/usr/sbin/sshd" hostname=172.21.6.210 addr=172.21.6.210 terminal=ssh res=success'
Sep 11 09:15:26 lepmaprpdn02 adclient[13162]: INFO  AUDIT_TRAIL|Centrify Suite|PAM|1.0|300|PAM account management granted|5|user=jlim(type:ad,JLim@TSYSECOM.ORG) pid=47244 utc=1536671726511 centrifyEventID=24300 status=GRANTED service=sshd tty=ssh client=172.21.6.210
Sep 11 09:15:26 lepmaprpdn02 sshd[47241]: Accepted keyboard-interactive/pam for jlim from 172.21.6.210 port 10207 ssh2
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=CRYPTO_KEY_USER msg=audit(1536671726.512:355096): pid=47241 uid=0 auid=4294967295 ses=4294967295 msg='op=destroy kind=session fp=? direction=both spid=47242 suid=74 rport=10207 laddr=10.123.128.25 lport=22  exe="/usr/sbin/sshd" hostname=? addr=172.21.6.210 terminal=? res=success'
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=USER_AUTH msg=audit(1536671726.513:355097): pid=47241 uid=0 auid=4294967295 ses=4294967295 msg='op=success acct="jlim" exe="/usr/sbin/sshd" hostname=? addr=172.21.6.210 terminal=ssh res=success'
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=CRED_ACQ msg=audit(1536671726.521:355098): pid=47241 uid=0 auid=4294967295 ses=4294967295 msg='op=PAM:setcred grantors=pam_centrifydc acct="jlim" exe="/usr/sbin/sshd" hostname=172.21.6.210 addr=172.21.6.210 terminal=ssh res=success'
Sep 11 09:15:26 lepmaprpdn02 adclient[13162]: INFO  AUDIT_TRAIL|Centrify Suite|PAM|1.0|200|PAM set credentials granted|5|user=jlim(type:ad,JLim@TSYSECOM.ORG) pid=47241 utc=1536671726522 centrifyEventID=24200 status=GRANTED service=sshd tty=ssh client=172.21.6.210
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=LOGIN msg=audit(1536671726.521:355099): pid=47241 uid=0 old-auid=4294967295 auid=1723878713 tty=(none) old-ses=4294967295 ses=34484 res=1
Sep 11 09:15:26 lepmaprpdn02 adclient[13162]: INFO  AUDIT_TRAIL|Centrify Suite|PAM|1.0|500|PAM open session granted|5|user=jlim(type:ad,JLim@TSYSECOM.ORG) pid=47241 utc=1536671726526 centrifyEventID=24500 status=GRANTED service=sshd tty=ssh client=172.21.6.210
Sep 11 09:15:26 lepmaprpdn02 systemd-logind: New session 34484 of user jlim.
Sep 11 09:15:26 lepmaprpdn02 systemd: Started Session 34484 of user jlim.
Sep 11 09:15:26 lepmaprpdn02 systemd: Starting Session 34484 of user jlim.
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=USER_START msg=audit(1536671726.532:355100): pid=47241 uid=0 auid=1723878713 ses=34484 msg='op=PAM:session_open grantors=pam_selinux,pam_loginuid,pam_selinux,pam_namespace,pam_keyinit,pam_centrifydc,pam_keyinit,pam_limits,pam_systemd,pam_unix,pam_lastlog acct="jlim" exe="/usr/sbin/sshd" hostname=172.21.6.210 addr=172.21.6.210 terminal=ssh res=success'
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=CRYPTO_KEY_USER msg=audit(1536671726.532:355101): pid=47245 uid=0 auid=1723878713 ses=34484 msg='op=destroy kind=server fp=SHA256:b0:5a:1f:70:24:e5:f4:64:51:97:af:2b:05:06:e8:dd:2e:b8:f1:53:be:75:de:05:2e:c8:d3:8c:0a:5b:fe:0f direction=? spid=47245 suid=0  exe="/usr/sbin/sshd" hostname=? addr=? terminal=? res=success'
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=CRYPTO_KEY_USER msg=audit(1536671726.533:355102): pid=47245 uid=0 auid=1723878713 ses=34484 msg='op=destroy kind=server fp=SHA256:5a:65:88:9d:62:f6:e5:77:45:df:2e:81:14:d6:9b:4a:d9:19:69:6a:51:42:e3:58:a4:66:c6:2a:36:94:0a:ed direction=? spid=47245 suid=0  exe="/usr/sbin/sshd" hostname=? addr=? terminal=? res=success'
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=CRYPTO_KEY_USER msg=audit(1536671726.533:355103): pid=47245 uid=0 auid=1723878713 ses=34484 msg='op=destroy kind=server fp=SHA256:7d:24:f2:3d:c6:fe:62:43:21:db:ea:0a:d2:c4:30:29:82:99:50:07:b7:b3:2f:98:60:7d:71:c3:f4:39:cd:8d direction=? spid=47245 suid=0  exe="/usr/sbin/sshd" hostname=? addr=? terminal=? res=success'
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=CRED_ACQ msg=audit(1536671726.534:355104): pid=47245 uid=0 auid=1723878713 ses=34484 msg='op=PAM:setcred grantors=pam_centrifydc acct="jlim" exe="/usr/sbin/sshd" hostname=172.21.6.210 addr=172.21.6.210 terminal=ssh res=success'
Sep 11 09:15:26 lepmaprpdn02 adclient[13162]: INFO  AUDIT_TRAIL|Centrify Suite|PAM|1.0|200|PAM set credentials granted|5|user=jlim(type:ad,JLim@TSYSECOM.ORG) pid=47245 utc=1536671726535 centrifyEventID=24200 status=GRANTED service=sshd tty=ssh client=172.21.6.210
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=USER_LOGIN msg=audit(1536671726.742:355105): pid=47241 uid=0 auid=1723878713 ses=34484 msg='op=login id=1723878713 exe="/usr/sbin/sshd" hostname=172.21.6.210 addr=172.21.6.210 terminal=/dev/pts/2 res=success'
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=USER_START msg=audit(1536671726.742:355106): pid=47241 uid=0 auid=1723878713 ses=34484 msg='op=login id=1723878713 exe="/usr/sbin/sshd" hostname=172.21.6.210 addr=172.21.6.210 terminal=/dev/pts/2 res=success'
Sep 11 09:15:26 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=CRYPTO_KEY_USER msg=audit(1536671726.743:355107): pid=47241 uid=0 auid=1723878713 ses=34484 msg='op=destroy kind=server fp=SHA256:7d:24:f2:3d:c6:fe:62:43:21:db:ea:0a:d2:c4:30:29:82:99:50:07:b7:b3:2f:98:60:7d:71:c3:f4:39:cd:8d direction=? spid=47246 suid=1723878713  exe="/usr/sbin/sshd" hostname=? addr=? terminal=? res=success'
Sep 11 09:15:26 lepmaprpdn02 dbus[1568]: [system] Activating service name='org.freedesktop.problems' (using servicehelper)
Sep 11 09:15:26 lepmaprpdn02 dbus-daemon: dbus[1568]: [system] Activating service name='org.freedesktop.problems' (using servicehelper)
Sep 11 09:15:26 lepmaprpdn02 dbus[1568]: [system] Activated service 'org.freedesktop.problems' failed: Failed to execute program /lib64/dbus-1/dbus-daemon-launch-helper: Success
Sep 11 09:15:26 lepmaprpdn02 dbus-daemon: dbus[1568]: [system] Activated service 'org.freedesktop.problems' failed: Failed to execute program /lib64/dbus-1/dbus-daemon-launch-helper: Success
Sep 11 09:15:36 lepmaprpdn02 smartd[14290]: Device: /dev/sdk, SMART Failure: FIRMWARE IMPENDING FAILURE SEEK ERROR RATE TOO HIGH
Sep 11 09:15:36 lepmaprpdn02 smartd[14290]: Device: /dev/bus/0 [megaraid_disk_21], SMART Failure: FIRMWARE IMPENDING FAILURE SEEK ERROR RATE TOO HIGH
Sep 11 09:15:57 lepmaprpdn02 kernel: SLUB: Unable to allocate memory on node -1 (gfp=0x8020)
Sep 11 09:15:57 lepmaprpdn02 kernel:  cache: ip6_dst_cache(399:572c44f89791131ed6320e904f7061a1c87e1a364764cb0b6d84ea8d9e09f75b), object size: 448, buffer size: 448, default order: 2, min order: 0
Sep 11 09:15:57 lepmaprpdn02 kernel:  node 0: slabs: 93, objs: 3078, free: 0
Sep 11 09:15:57 lepmaprpdn02 kernel:  node 1: slabs: 71, objs: 2367, free: 0
Sep 11 09:16:14 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=CRYPTO_KEY_USER msg=audit(1536671774.231:355108): pid=47241 uid=0 auid=1723878713 ses=34484 msg='op=destroy kind=server fp=SHA256:7d:24:f2:3d:c6:fe:62:43:21:db:ea:0a:d2:c4:30:29:82:99:50:07:b7:b3:2f:98:60:7d:71:c3:f4:39:cd:8d direction=? spid=47245 suid=1723878713  exe="/usr/sbin/sshd" hostname=? addr=? terminal=? res=success'
Sep 11 09:16:14 lepmaprpdn02 audispd: node=lepmaprpdn02.tsysecom.org type=CRYPTO_KEY_USER msg=audit(1536671774.231:355109): p
