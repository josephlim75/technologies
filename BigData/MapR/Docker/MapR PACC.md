## Reference

https://maprdocs.mapr.com/52/AdvancedInstallation/RunningtheMapRPACC.html

## Docker run

    docker run -it -e MAPR_CLUSTER=<cluster-name> -e MAPR_TZ=<time-zone> -e MAPR_CLDB_HOSTS=<cldb-list> -e MAPR_CONTAINER_USER=<user-name> -e MAPR_CONTAINER_UID=<uid> -e MAPR_CONTAINER_GID=<gid> -e MAPR_CONTAINER_GROUP=<group-name> -e MAPR_TICKETFILE_LOCATION=/tmp/mapr_ticket -v <ticket-file-host-location>:/tmp/mapr_ticket:ro -e MAPR_MOUNT_PATH=<path_to_fuse_mount_point> --cap-add SYS_ADMIN --cap-add SYS_RESOURCE --device /dev/fuse --security-opt apparmor:unconfined <image-name>
    
Following are four examples for using the docker run command:

- Secure Cluster with FUSE-Based POSIX Client
- Secure Cluster without FUSE-Based POSIX Client
- Non-Secure Cluster with FUSE-Based POSIX Client
- Non-Secure Cluster without FUSE-Based POSIX Client

The following command generates a service ticket on the cluster or a client that is valid for 30 days. (For more maprlogin command examples, see maprlogin Command Examples).

    maprlogin generateticket -type service -cluster cluster1 -duration 30:0:0 -out /tmp/bobs_ticket

The ticket can be copied from /tmp/bobs_ticket to /user/tickets/bobs_ticket on the container host and used in the following docker run commands for secure clusters:

### Secure Cluster with FUSE-Based POSIX Client

    docker run -it -e MAPR_CLUSTER=cluster1 -e MAPR_CLDB_HOSTS=CLDB_1,CLDB_2 -e MAPR_CONTAINER_USER=bob -e MAPR_TICKETFILE_LOCATION=/tmp/mapr_ticket -v  /user/tickets/bobs_ticket:/tmp/mapr_ticket:ro -e MAPR_MOUNT_PATH=/mapr --cap-add SYS_ADMIN --cap-add SYS_RESOURCE --device /dev/fuse maprtech/pacc:5.2.1_3.0_centos7

### Secure Cluster without FUSE-Based POSIX Client

    docker run -it -e MAPR_CLUSTER=cluster1 -e MAPR_CLDB_HOSTS=CLDB_1,CLDB_2 -e MAPR_CONTAINER_USER=bob -e MAPR_TICKETFILE_LOCATION=/tmp/mapr_ticket -v  /user/tickets/bobs_ticket:/tmp/mapr_ticket:ro maprtech/pacc:5.2.1_3.0_centos7

### Non-Secure Cluster with FUSE-Based POSIX Client

In a non-secure cluster, specifying the MAPR_CONTAINER_USER, MAPR_CONTAINER_GROUP, MAPR_CONTAINER_UID, and MAPR_CONTAINER_GID is strongly recommended, and these values must match the user credentials on the server:

    docker run -it --cap-add SYS_ADMIN --cap-add SYS_RESOURCE --device /dev/fuse -e MAPR_CLUSTER=cluster1 -e MAPR_CLDB_HOSTS=CLDB_1,CLDB_2 -e MAPR_CONTAINER_USER=bob -e MAPR_CONTAINER_GROUP=dev -e MAPR_CONTAINER_UID=10000 -e MAPR_CONTAINER_GID=10000 -e MAPR_MOUNT_PATH=/mapr maprtech/pacc:5.2.1_3.0_centos7

### Non-Secure Cluster without FUSE-Based POSIX Client

In a non-secure cluster, specifying the MAPR_CONTAINER_USER, MAPR_CONTAINER_GROUP, MAPR_CONTAINER_UID, and MAPR_CONTAINER_GID is strongly recommended, and these values must match the user credentials on the server:

    docker run -it -e MAPR_CLUSTER=cluster1 -e MAPR_CLDB_HOSTS=CLDB_1,CLDB_2 -e MAPR_CONTAINER_USER=bob -e MAPR_CONTAINER_GROUP=dev -e MAPR_CONTAINER_UID=10000 -e MAPR_CONTAINER_GID=10000 maprtech/pacc:5.2.1_3.0_centos7

Tip:  To re-launch a container, you can use these Docker commands:

    # docker ps -a
    # docker start <container-run-ID>

Use docker start -i if you need to start with an interactive shell.

## Verifying the Launch of the MapR PACC

After running the docker run command, you should see the Starting services message. For example:

    Starting services (mapr-posix-client-container)...
    Started service mapr-posix-client-container
    ...Success
    $

When the installation is successful, the client connects to the cluster, storage is mounted, and the FUSE POSIX client is started automatically. Use the ls $MAPR_MOUNT_PATH command to test the connection to the cluster. This command should return the cluster name. For example:

    $ ls $MAPR_MOUNT_PATH
    cluster1

To display some directories on the cluster, use this command:

    $ ls $MAPR_MOUNT_PATH/cluster1
    apps var user hbase opt tmp    
