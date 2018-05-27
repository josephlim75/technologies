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

### Option 3

- Run with kafka tools :
```
    kafka-configs.sh --alter --entity-type topics \
      --zookeeper zookeeper01.kafka.com --add-config \
      retention.ms=1 --entity-name <topic-name>
```
- Run on Schema registry node:
```
    kafka-avro-console-consumer --consumer-property security.protocol=SSL --consumer-property \
      ssl.truststore.location=/etc/schema-registry/secrets/trust.jks --consumer-property \
      ssl.truststore.password=password --consumer-property \
      ssl.keystore.location=/etc/schema-registry/secrets/identity.jks --consumer-property \
      ssl.keystore.password=password --consumer-property ssl.key.password=password --bootstrap-server \
      broker01.kafka.com:9092 --topic <topic-name> --new-consumer --from-beginning    
```
- Set topic retention back to the original setting, once topic is empty.
```
    bash kafka-configs.sh --alter --entity-type topics \
      --zookeeper zookeeper01.kafka.com \
      --add-config retention.ms=604800000 --entity-name <topic-name>
```    
Hope this helps someone, as it isn't easily advertised.    
