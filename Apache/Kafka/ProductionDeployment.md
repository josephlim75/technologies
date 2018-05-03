## Production Deployment

This section is not meant to be an exhaustive guide to running your Kafka cluster in production, but it covers the key things to consider before putting your cluster live

Three main areas are covered:

- Logistical considerations, such as hardware recommendations and deployment strategies

- Configuration changes that are more suited to a production environment

- Post-deployment considerations, such as data rebalancing, multi-data center setup

### Hardware

If you’ve been following the normal development path, you’ve probably been playing with Kafka on your laptop or on a small cluster of machines laying around. But when it comes time to deploying Kafka to production, there are a few recommendations that you should consider. Nothing is a hard-and-fast rule; Kafka is used for a wide range of use cases and on a bewildering array of machines. But these recommendations provide good starting points based on our experience with production clusters.

### Memory

Kafka relies heavily on the filesystem for storing and caching messages. All data is immediately written to a persistent log on the filesystem without necessarily flushing to disk. In effect this just means that it is transferred into the kernel’s pagecache. A modern OS will happily divert all free memory to disk caching with little performance penalty when the memory is reclaimed. Furthermore, Kafka uses heap space very carefully and does not require setting heap sizes more than 5GB. This will result in a file system cache of up to 28-30GB on a 32GB machine.

You need sufficient memory to buffer active readers and writers. You can do a back-of-the-envelope estimate of memory needs by assuming you want to be able to buffer for 30 seconds and compute your memory need as `write_throughput * 30`.

A machine with 64 GB of RAM is a decent choice, but 32 GB machines are not uncommon. Less than 32 GB tends to be counterproductive (you end up needing many, many small machines).


### CPUs

Most Kafka deployments tend to be rather light on CPU requirements. As such, the exact processor setup matters less than the other resources. Note that if SSL is enabled, the CPU requirements can be significantly higher (the exact details depend on the CPU type and JVM implementation).

You should choose a modern processor with multiple cores. Common clusters utilize 24 core machines.

If you need to choose between faster CPUs or more cores, choose more cores. The extra concurrency that multiple cores offers will far outweigh a slightly faster clock speed.

### Disks

We recommend using multiple drives to get good throughput and not sharing the same drives used for Kafka data with application logs or other OS filesystem activity to ensure good latency. As of 0.8 you can either RAID these drives together into a single volume or format and mount each drive as its own directory. Since Kafka has replication the redundancy provided by RAID can also be provided at the application level. This choice has several tradeoffs.

If you configure multiple data directories partitions will be assigned round-robin to data directories. Each partition will be entirely in one of the data directories. If data is not well balanced among partitions this can lead to load imbalance between disks.

RAID can potentially do better at balancing load between disks (although it doesn’t always seem to) because it balances load at a lower level. The primary downside of RAID is that it reduces the available disk space. Another potential benefit of RAID is the ability to tolerate disk failures.

We don’t recommend RAID 5 or RAID 6 because of the significant hit on write throughput and, to a lesser extent, the I/O cost of rebuilding the array when a disk fails (the rebuild cost applies to RAID, in general, but it is worst for RAID 6 and then RAID 5).

Our recommendation is to use RAID 10 if the additional cost is acceptable. Otherwise, configure your Kafka server with multiple log directories, each directory mounted on a separate drive.

Finally, avoid network-attached storage (NAS). People routinely claim their NAS solution is faster and more reliable than local drives. Despite these claims, we have never seen NAS live up to its hype. NAS is often slower, displays larger latencies with a wider deviation in average latency, and is a single point of failure.

### Network

A fast and reliable network is obviously important to performance in a distributed system. Low latency helps ensure that nodes can communicate easily, while high bandwidth helps shard movement and recovery. Modern data-center networking (1 GbE, 10 GbE) is sufficient for the vast majority of clusters.

Avoid clusters that span multiple data centers, even if the data centers are colocated in close proximity. Definitely avoid clusters that span large geographic distances.

Kafka clusters assume that all nodes are equal—not that half the nodes are actually 150ms distant in another data center. Larger latencies tend to exacerbate problems in distributed systems and make debugging and resolution more difficult.

Similar to the NAS argument, everyone claims that their pipe between data centers is robust and low latency. This is true—until it isn’t (a network failure will happen eventually; you can count on it). From our experience, the hassle and cost of managing cross–data center clusters is simply not worth the benefits.

### Filesystem

We recommend running Kafka on XFS or ext4. XFS typically performs well with little tuning when compared to ext4 and it has become the default filesystem for many Linux distributions.

General considerations
It is possible nowadays to obtain truly enormous machines: hundreds of gigabytes of RAM with dozens of CPU cores. Conversely, it is also possible to spin up thousands of small virtual machines in cloud platforms such as EC2. Which approach is best?

In general, it is better to prefer medium-to-large boxes. Avoid small machines, because you don’t want to manage a cluster with a thousand nodes, and the overhead of simply running Kafka is more apparent on such small boxes.

At the same time, avoid the truly enormous machines. They often lead to imbalanced resource usage (for example, all the memory is being used, but none of the CPU) and can add logistical complexity if you have to run multiple nodes per machine.

### JVM

We recommend running the latest version of JDK 1.8 with the G1 collector (older freely available versions have disclosed security vulnerabilities).

If you are still on JDK 1.7 (which is also supported) and you are planning to use G1 (the current default), make sure you’re on u51. We tried out u21 in testing, but we had a number of problems with the GC implementation in that version.

Our recommended GC tuning (tested on a large deployment with JDK 1.8 u5) looks like this:

	-Xms6g -Xmx6g -XX:MetaspaceSize=96m -XX:+UseG1GC -XX:MaxGCPauseMillis=20
		   -XX:InitiatingHeapOccupancyPercent=35 -XX:G1HeapRegionSize=16M
		   -XX:MinMetaspaceFreeRatio=50 -XX:MaxMetaspaceFreeRatio=80

For reference, here are the stats on one of LinkedIn’s busiest clusters (at peak):

	60 brokers
	50k partitions (replication factor 2)
	800k messages/sec in
	300 MB/sec inbound, 1 GB/sec+ outbound
	
The tuning looks fairly aggressive, but all of the brokers in that cluster have a 90% GC pause time of about 21ms, and they’re doing less than 1 young GC per second.