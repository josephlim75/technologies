## Confluent JVM for Production

-Xms6g -Xmx6g -XX:MetaspaceSize=96m -XX:+UseG1GC -XX:MaxGCPauseMillis=20
       -XX:InitiatingHeapOccupancyPercent=35 -XX:G1HeapRegionSize=16M
       -XX:MinMetaspaceFreeRatio=50 -XX:MaxMetaspaceFreeRatio=80

For reference, here are the stats on one of LinkedIn’s busiest clusters (at peak):

- 60 brokers
- 50k partitions (replication factor 2)
- 800k messages/sec in
- 300 MB/sec inbound, 1 GB/sec+ outbound

The tuning looks fairly aggressive, but all of the brokers in that cluster have a 90% GC pause time of about 21ms, and they’re doing less than 1 young GC per second.

## Remove index and let it rebuild

    sudo find $your_data_directory -size 10485760c -name *.index -delete

    bin/kafka-run-class kafka.tools.GetOffsetShell --broker-list 10.123.128.22:9092,10.123.128.23:9092,10.123.128.25:9092,10.123.128.26:9092,10.123.128.28:9092 -topic raw_capture_ts2_ims_core_consumer_accounts -time -1 --offsets 1 | awk -F ":" '{sum += $3} END {print sum}'

## Sending Large Message Size in Kafka
- **Consumer side**:` fetch.message.max.bytes` - this will determine the largest size of a message that can be fetched by the consumer.
- **Broker side**: `replica.fetch.max.bytes` - this will allow for the replicas in the brokers to send messages within the cluster and make sure the messages are replicated correctly. If this is too small, then the message will never be replicated, and therefore, the consumer will never see the message because the message will never be committed (fully replicated).
- **Broker side**: `message.max.bytes` - this is the largest size of the message that can be received by the broker from a producer.
- **Broker side (per topic)**: `max.message.bytes` - this is the largest size of the message the broker will allow to be appended to the topic. This size is validated pre-compression. (Defaults to broker's message.max.bytes.)

I found out the hard way about number 2 - you don't get ANY exceptions, messages, or warnings from Kafka, so be sure to consider this when you are sending large messages.

I had only set the `message.max.bytes` in the source code. But I have to set these values in the configuration of the Kafka server `config/server.properties`. Now also bigger messages work :).

Minor changes required for **Kafka 0.10** and the new consumer compared to laughing_man's answer:

- **Broker**: No changes, you still need to increase properties message.max.bytes and replica.fetch.max.bytes. message.max.bytes has to be equal or smaller(*) than replica.fetch.max.bytes.
- **Producer**: Increase max.request.size to send the larger message.
- **Consumer**: Increase max.partition.fetch.bytes to receive larger messages.
(*) Read the comments to learn more about `message.max.bytes<=replica.fetch.max.bytes`

You need to override the following properties:

Broker Configs($KAFKA_HOME/config/server.properties)

replica.fetch.max.bytes
message.max.bytes
Consumer Configs($KAFKA_HOME/config/consumer.properties) 
This step didn't work for me. I add it to the consumer app and it was working fine

fetch.message.max.bytes
Restart the server.

---

- Just don't send 4GB messages as 1 message. If it's something around 10-20MB its ok, but not GB.
- Of course even 10s of MB are more than you can handle by default. See 
http://stackoverflow.com/questions/21020347/kafka-sending-a-15mb-message for details. It's old, so your config would differ, but the idea is the same. TLDR:

You need to adjust three (or four) properties:
- Don't use multiprocessing if you're only sending data without compression or preprocessing. Multiprocessing will copy your messages to new processes and spawning/killing processes will make it slow. Just create 1 producer and send data to it, the task should not be CPU bound.
In kafka-python use max_partition_fetch_bytes instead of fetch.message.max.bytes. Later one is for old consumer.
Also what version of the broker are you using? If it's the newest one (0.10.1+) it should handle large messages without max.partition.fetch.bytes option on the Consumer.

---

## How to decrease message latency

There are two builtin end-to-end latencies in librdkafka:

- Producer batch latency - `queue.buffering.max.ms` (alias `linger.ms`) - how long the producer waits for more messages to be .._produce()d by the app before sending them off to the broker in one batch of messages.
- Consumer batch latency - `fetch.wait.max.ms` - how much time the consumer gives the broker to fill up fetch.min.bytes worth of messages before responding.

When trying to minimize end-to-end latency it is important to adjust both of these settings:

- producer: `queue.buffering.max.ms` - set to 0 for immediate transmission, or some other low reasonable value (e.g. 5 ms)
- consumer: `fetch.wait.max.ms` - set to your allowed maximum latency, e.g. 10 (ms).

Setting `fetch.wait.max.ms` too low (lower than the partition message rate) causes the occassional FetchRequest to return empty before any new messages were seen on the broker, this in turn kicks in the `fetch.error.backoff.ms` timer that waits that long before the next FetchRequest. 
So you might want to decrease `fetch.error.backoff.ms` too.

In librdkafka <=0.9.2, or on **Windows**, you'll also want to minimize `socket.blocking.max.ms` for both producer and consumer.

== Topic Deletion

*Topic Deletion* is a feature of Kafka that allows for deleting topics.

link:kafka-TopicDeletionManager.adoc[TopicDeletionManager] is responsible for topic deletion.

Topic deletion is controlled by link:kafka-properties.adoc#delete.topic.enable[delete.topic.enable] Kafka property that turns it on when `true`.

Start a Kafka broker with broker ID `100`.

```
$ ./bin/kafka-server-start.sh config/server.properties \
  --override delete.topic.enable=true \
  --override broker.id=100 \
  --override log.dirs=/tmp/kafka-logs-100 \
  --override port=9192
```

Create *remove-me* topic.

```
$ ./bin/kafka-topics.sh --zookeeper localhost:2181 \
  --create \
  --topic remove-me \
  --partitions 1 \
  --replication-factor 1
Created topic "remove-me".
```

Use `kafka-topics.sh --list` to list available topics.

```
$ ./bin/kafka-topics.sh --zookeeper localhost:2181 --list
__consumer_offsets
remove-me
```

Use `kafka-topics.sh --describe` to list details for `remove-me` topic.

```
$ ./bin/kafka-topics.sh --zookeeper localhost:2181 --describe --topic remove-me
Topic:remove-me	PartitionCount:1	ReplicationFactor:1	Configs:
	Topic: remove-me	Partition: 0	Leader: 100	Replicas: 100	Isr: 100
```

Note that the broker `100` is the leader for `remove-me` topic.

Stop the broker `100` and start another with broker ID `200`.

```
$ ./bin/kafka-server-start.sh config/server.properties \
  --override delete.topic.enable=true \
  --override broker.id=200 \
  --override log.dirs=/tmp/kafka-logs-200 \
  --override port=9292
```

Use `kafka-topics.sh --delete` to delete `remove-me` topic.

```
$ ./bin/kafka-topics.sh --zookeeper localhost:2181 --delete --topic remove-me
Topic remove-me is marked for deletion.
Note: This will have no impact if delete.topic.enable is not set to true.
```

List the topics.

```
$ ./bin/kafka-topics.sh --zookeeper localhost:2181 --list
__consumer_offsets
remove-me - marked for deletion
```

As you may have noticed, `kafka-topics.sh --delete` will only delete a topic if the topic's leader broker is available (and can acknowledge the removal). Since the broker 100 is down and currently unavailable the topic deletion has only been recorded in Zookeeper.

```
$ ./bin/zkCli.sh -server localhost:2181
[zk: localhost:2181(CONNECTED) 0] ls /admin/delete_topics
[remove-me]
```

As long as the leader broker `100` is not available, the topic to be deleted remains marked for deletion.

Start the broker `100`.

```
$ ./bin/kafka-server-start.sh config/server.properties \
  --override delete.topic.enable=true \
  --override broker.id=100 \
  --override log.dirs=/tmp/kafka-logs-100 \
  --override port=9192
```

With link:kafka-KafkaController.adoc#logging[kafka.controller.KafkaController] logger at `DEBUG` level, you should see the following messages in the logs:

```
DEBUG [Controller id=100] Delete topics listener fired for topics remove-me to be deleted (kafka.controller.KafkaController)
INFO [Controller id=100] Starting topic deletion for topics remove-me (kafka.controller.KafkaController)
INFO [GroupMetadataManager brokerId=100] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
DEBUG [Controller id=100] Removing replica 100 from ISR 100 for partition remove-me-0. (kafka.controller.KafkaController)
INFO [Controller id=100] Retaining last ISR 100 of partition remove-me-0 since unclean leader election is disabled (kafka.controller.KafkaController)
INFO [Controller id=100] New leader and ISR for partition remove-me-0 is {"leader":-1,"leader_epoch":1,"isr":[100]} (kafka.controller.KafkaController)
INFO [ReplicaFetcherManager on broker 100] Removed fetcher for partitions remove-me-0 (kafka.server.ReplicaFetcherManager)
INFO [ReplicaFetcherManager on broker 100] Removed fetcher for partitions  (kafka.server.ReplicaFetcherManager)
INFO [ReplicaFetcherManager on broker 100] Removed fetcher for partitions remove-me-0 (kafka.server.ReplicaFetcherManager)
INFO Log for partition remove-me-0 is renamed to /tmp/kafka-logs-100/remove-me-0.fe6d039ff884498b9d6113fb22a75264-delete and is scheduled for deletion (kafka.log.LogManager)
DEBUG [Controller id=100] Delete topic callback invoked for org.apache.kafka.common.requests.StopReplicaResponse@8c0f4f0 (kafka.controller.KafkaController)
INFO [Controller id=100] New topics: [Set()], deleted topics: [Set()], new partition replica assignment [Map()] (kafka.controller.KafkaController)
DEBUG [Controller id=100] Delete topics listener fired for topics  to be deleted (kafka.controller.KafkaController)
```

The topic is now deleted. Use Zookeeper CLI tool to confirm it.

```
$ ./bin/zkCli.sh -server localhost:2181
[zk: localhost:2181(CONNECTED) 1] ls /admin/delete_topics
[]
```
