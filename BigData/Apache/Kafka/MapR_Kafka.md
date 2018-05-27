## Running Apache Kafka on MapR-FS

The MapR data platform is extremely versatile, and the POSIX implementation allows us to run pretty much any application we like on the MapR distributed file system, MapR FS.

Take, for example, Apache Kafka. We recently announced MapR Streams, a Kafka-API-compatible pub/sub messaging system built in to the data platform. It has some advantages over Kafka, but we recognize that in some cases folks might prefer to stick with Kafka if they’re already using it. And we’re cool with that! In fact, if you’ve just built a MapR Enterprise edition cluster you might be interested to know that in addition to your Hadoop and NoSQL workloads, you can also run Kafka directly on your MapR cluster nodes.

MapR includes a distribution of Hadoop, and MapR FS provides an HDFS implementation. The HDFS implementation is key to enabling the Hadoop ecosystem. However, MapR also provides a POSIX interface, which Kafka can use just the same as it would a local disk. Kafka just runs, as usual (with one minor exception, which we’ll cover later).

Another powerful capability of MapR is topology, or “data placement control”. Topology is a linchpin of multi-tenancy on MapR, and allows us confine compute and storage to a particular set of nodes. At scale, Kafka can be demanding of an I/O subsystem.

What we can do to avoid resource contention is create a topology path just for Kafka, such that the nodes running Kafka will be guaranteed to be isolated from other cluster activity such as MapR FS replication traffic or YARN tasks. Another benefit here is that the kafka nodes can be different from the other MapR nodes. Your MapR processing nodes may have a different spec to the nodes that make up the Kafka cluster, yet still be managed under the MapR umbrella. The kafka services will be manageable and monitored by the MapR warden.

So why would you use MapR FS if you’re going to isolate the nodes anyway? One reason is that both your Kafka and MapR clusters have several disks, and you may want one way to manage failures when they happen. Monitoring for multiple failure modes adds some operational complexity you might prefer to avoid. It may simplify things to have one procedure to manage failure in disks, and I’d argue that it’s reasonable to have that procedure be the one being used in the larger cluster, which is likely to be your MapR cluster.

Another consideration when using Kafka on MapR FS is replication. Kafka handles replication on its own, so you almost certainly don’t want MapR FS also replicating data around underneath Kafka. That would be wasteful. Instead, use a MapR volume for each Kafka node, configured as a local volume with desired and minimum replication set to 1, which means that it will not replicate to another node, and all writes will be local. Kafka will work as usual, just with MapR FS as backing storage.
One important but subtle point I should add is that node-local volumes are different than simply creating a volume with the replication factor set to 1. If I create a volume on MapR with replication=1, writes can be made to the volume from any node in cluster. With a replication factor of 1, I’ll get only one copy of the data. But if writes are coming from multiple nodes, the data will be scattered across multiple nodes. This is because setting a replication factor does not constrain where the single copy of the data can live - it only says there will be one copy. So while isolating the nodes and setting replication=1 will have the desired effect if the kafka nodes are isolated, it will not guarantee that the first (and only) copy of the data will reside on one node - only configuring a local volume will do that. In this case, we’ll use node local and replication=1 to ensure that the data that kafka writes to MFS does not need to travel over the network at all.

So how do we set this up? Here’s the high level steps to implement.

- Select some nodes. If you’re building a new MapR cluster or adding nodes to an existing one, the hardware for Kafka does not need to be identical to the other nodes. That’s up to you. But again, the operational impact and procedural burden of varying nodes needs to be weighed.

- Create a topology path for the kafka nodes and volumes. This is necessary if you want segregate the Kafka workload from the other work going on in the cluster to avoid resource contention.

- Create a local volume for each Kafka node. This ensures that all I/O from the owning node is local (e.g., not over the network).

- Move the kafka nodes and the kafka volumes to the kafka topology path you created in step 2.

- For each kafka node, mount the volume via MapR NFS or the FUSE posix client. If using NFS, use the `nolock` option. Remember when I said “with one exception” earlier? MapR FS does not support a network lock manager, but the nolock allows the client to enforce locking locally. This works well enough for Kafka, since we are mainly trying to prevent multiple local processes writing to the same partitions. The fact that we’re placing our partitions on a distributed file system means we’ll need to take some care in ensuring that multiple nodes don’t end up writing to the same directory, since the way Kafka implements locking will not work reliably over NFS.

- Install a Warden configuration file so that Warden can stop and start Kafka with the cluster, and so that it can be managed via maprcli, the REST API and MCS.

That's about it. Start up Kafka, and test!

I've implemented some automation to help with deploying Kafka on MapR as I described above. The ansible role is available on github: https://github.com/vicenteg/mapr-kafka
If you try the ansible role and have trouble or questions, reply here, or file issues in the github repository.
