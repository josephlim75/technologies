## Purge Topic

### Option 1

Temporarily update the retention time on the topic to one second:

    kafka-topics.sh --zookeeper localhost:13003 --alter --topic MyTopic --config retention.ms=1000
    
then wait for the purge to take effect (about one minute). Once purged, restore the previous retention.ms value.

### Option 2

Here are the steps I follow to delete a topic named MyTopic:

- Stop the Apache Kafka daemon
- Delete the topic data folder: `rm -rf /tmp/kafka-logs/MyTopic-0`
- Delete the topic metadata: `zkCli.sh` then `rmr /brokers/MyTopic`
- Start the Apache Kafka daemon

