## MapR Administration

https://maprdocs.mapr.com/home/AdministratorGuide/ClstrAdminOverview.html

## Checking Ace Support

    # maprcli config load -json | grep "mfs.feature.db.ace.support" 
    "mfs.feature.db.ace.support":"0",
    
    # maprcli config save -values '{"mfs.feature.db.ace.support":"1"}'  

## MapR Installation

### Upgrade to MapR 6.1.0
- [MapR OS Support Matrix](https://mapr.com/docs/home/InteropMatrix/r_os_matrix_6.x.html)
- [MapR Check Cluster](https://mapr.com/docs/home/UpgradeGuide/RestartingClusterServices.html)

OS Version | MapR 6.1.0 | MapR 6.0.1 | MapR 6.0.0 | MapR 5.2.2
--- | --- | --- | --- | ---
RHEL 7.5 |Yes |No | No | Yes
RHEL 7.4 |Yes |Yes |Yes | Yes

- Stop al MapR eco packages services, hs2, oozie, hue

        maprcli node services -multi '[{ "name": "", "action": "stop"}, { "name": "oozie", "action": "stop"}, { "name": "hs2", "action": "stop"}]' -nodes

### Data-on-wire-encryption
- Beginnning with MapR 6.1, data-on-wire-encryption is enabled by defualt for newly created volumes on secured clusters

### Metrics Monitoring
- MapR 6.1.0 requires a minimal level of metrics monitoring to be configured to support metering.

## Re-formatting a Node

- Skip to end of metadataGo to start of metadata
- Change to the root user (or use sudo for the following commands).
- Stop the Warden:
    
      service mapr-warden stop

- Remove the disktab file:

      rm /opt/mapr/conf/disktab

- Create a text file /tmp/disks.txt that lists all the disks and partitions to format for use by MapR. See Setting Up Disks for MapR.

- Use disksetup to re-format the disks:
    
      disksetup -F /tmp/disks.txt

- Start the Warden:

      service mapr-warden start

## Changing Cluster name

Changing Cluster name

- Directly change your cluster name in `/opt/mapr/conf/mapr-clusters.conf`.

- Sync new `/opt/mapr/conf/mapr-clusters.conf` file on all the cluster nodes and edge nodes also.

- We only need to restart the WebUI service to see the new cluster name on MCS UI.

 
## Setting CLDB-Only node
- INSTALL the following packages to the node.
  
      mapr-cldb
      mapr-webserver
      mapr-core
      mapr-fileserver

- Move all CLDB nodes to a CLDB-only topology (e. g. /cldbonly) using the MapR Control System or the following command:
    
      maprcli node move -serverids <CLDB nodes> -topology /cldbonly

- Restrict the CLDB volume to the CLDB-only topology using the MapR Control System or the following command:
    
      maprcli volume move -name mapr.cldb.internal -topology /cldbonly

- If the CLDB volume is present on nodes not in /cldbonly, increase the replication factor of mapr.cldb.internal to create enough copies in /cldbonly using the MapR Control System or the following command:

      maprcli volume modify -name mapr.cldb.internal -replication <replication factor>

- Once the volume has sufficient copies, remove the extra replicas by reducing the replication factor to the desired value using the MapR Control System or the command used in the previous step.

- Move all non-CLDB nodes to a non-CLDB topology (eg. `/defaultrack`) using the MapR Control System or the following command: `maprcli node move -serverids <all non-CLDB nodes> -topology /defaultrack`

- Restrict all existing volumes to the topology `/defaultrack` using the MapR Control System or the following command: `maprcli volume move -name <volume> -topology /defaultrack`
All volumes except `mapr.cluster.root` are re-replicated to the changed topology automatically.

- **Warning**: To prevent subsequently created volumes from encroaching on the CLDB-only nodes, set a default topology that excludes the CLDB-only topology.    
    
## Putting Node into Maintenance Mode
- To put a node into maintenance mode, follow this process:
- From a terminal, issue the node maintenance command:

      maprcli node maintenance -nodes <IP|hostname> -timeoutminutes <minutes>

- When running this command, specify a timeout (in minutes) long enough for you to perform necessary maintenance on the node.

**Note**: For the duration of the timeout, the cluster's CLDB does not consider this node's data as lost and does not trigger a resync of the data on this node. However, if a node is put under maintenance for more than 5 minutes, MapR Filesystem will be shut down on that node so that any client(s) accessing containers on this node will get appropriate error and retry other container copies.
Stop warden on the node.
    
Mapr Sudoers
==============
root    ALL= (ALL)      ALL
+rootusers      ALL= (ALL)      ALL
mapr    ALL= (root)     NOPASSWD:       /sbin/ip
mapr    ALL= (root)     NOPASSWD:       /bin/mount
mapr    ALL= (root)     NOPASSWD:       /bin/umount
mapr    ALL= (root)     NOPASSWD:       /sbin/ifconfig
mapr    ALL= (root)     NOPASSWD:       /usr/bin/arping
mapr    ALL= (root)     NOPASSWD:       /opt/mapr/server/pmapset
mapr    ALL= (root)     NOPASSWD:       /opt/mapr/server/mrdisk
mapr    ALL= (root)     NOPASSWD:       /bin/chgrp
mapr    ALL= (root)     NOPASSWD:       /bin/chmod
mapr    ALL= (root)     NOPASSWD:       /usr/bin/renice
mapr    ALL= (root)     NOPASSWD:       /usr/sbin/dmidecode
mapr    ALL= (root)     NOPASSWD:       /sbin/hdparm
mapr    ALL= (root)     NOPASSWD:       /usr/bin/sdparm
mapr    ALL= (root)     NOPASSWD:       /opt/mapr/server/suexec

Version
==========

The file /opt/mapr/MapRBuildVersion is updated automatically on each node during an upgrade, to set the new version.  If you are using the Installer, it should then update the cluster-wide mapr.targetversion value to match; if you upgrade manually you have to do that as a post-upgrade step.
 
To see what MapR has as the target version, run:
 
maprcli config load -keys mapr.targetversion
 
It should match what is in /opt/mapr/MapRBuildVersion.  If it does not, update it with:
 
maprcli config save -values {mapr.targetversion:"`cat /opt/mapr/MapRBuildVersion`"}
 
That might resolve the alarm you're seeing.


configure.bat -N mapr-cluster -c -secure -C 10.32.49.11:7222,10.32.49.12:7222

Dev Environment
==================
mapr/m@prdev0!@10.32.48.134:8443

Production Cluster Environment
================================
mapr/M@prpoc0!@10.123.128.20:8443



https://mapr.com/blog/getting-started-mapr-command-line-part-i/

MaprCLI 101 Commands 
=====================

Get the servers id and hostname
  $ maprcli node list -columns hostname,id
  id                   hostname     ip          
  4800813424089433352  node-28.lab  10.10.20.28 
  6881304915421260685  node-29.lab  10.10.20.29 
  4760082258256890484  node-31.lab  10.10.20.31 
  8350853798092330580  node-32.lab  10.10.20.32 
  2618757635770228881  node-33.lab  10.10.20.33

Restarting Services by node and name
  $ maprcli node services -name resourcemanager -action restart -nodes '10.32.42.26 10.32.42.27'
  $ maprcli node services -name nodemanager -action restart -nodes '10.32.42.28 10.32.42.29 10.32.42.30 10.32.42.31'

Find server id by hostname or ip
awk - Find and Print 
  $ maprcli node list -columns hostname,id | awk '/10.32.42.30/{print $3}'

SMTP Setting
  $ maprcli config save -values '{"mapr.smtp.provider":"other","mapr.smtp.server":"smtpgw.us.txxx.com","mapr.smtp.sslrequired":"false","mapr.smtp.port":"25","mapr.smtp.sender.fullname":"EDP Support","mapr.smtp.sender.email":"edp.support@txxx.com","mapr.smtp.sender.username":"edp.support@txx.om","mapr.smtp.sender.password":""}'

Show who has access to WebUI
  $ maprcli acl show -type cluster
  
List node and its roles
  $ maprcli node list -columns service
    maprcli node list -columns csvc

List node with json format 
  $ maprcli node list -json
 
List entity usage
  $ maprcli entity list

Cluster Permissions
  login(including cv): Log in to the Control System, use the API and command-line interface, read access on cluster and volumes
  ss:Start/stop services
  cv:Create volumes
  a:Admin access
  fc:Full control (administrative access and permission to change the cluster ACL)

Volume Permission
  dump:Dump the volume
  restore:Mirror or restore the volume
  m:Modify volume properties, create and delete snapshots
  d:Delete a volume
  fc:Full control (admin access and permission to change volume ACL)

List ACL
$ maprcli acl show -type cluster
Principal     Allowed actions         
User root     [login, ss, cv, a, fc]  
User gpadmin  [login, ss, cv, a, fc] 
 
$ maprcli acl show -type volume -name mynamevol -user root
Principal  Allowed actions            
User root  [dump, restore, m, d, fc] 

Modify ACL for a user
$ maprcli acl edit -type cluster -user myname:cv
$ maprcli acl edit -type cluster -user _svctokensvcqa:login,ss,cv,fc
$ maprcli acl edit -type cluster -group datalake_qa_app_devs:login,ss,cv,a,fc
$ maprcli acl edit -type cluster -user myname:a
$ maprcli acl edit -type volume -name mynamevol -user myname:m

Modify ACL for a whole cluster or volume
$ maprcli acl set -type volume -name test-volume -user jsmith:dump,restore,m rjones:fc

Volume Quotum
$ maprcli volume modify -name mynamevol -quota 2G

Entity Quotum
$ maprcli entity modify -type 0 -name myname -quota 1T