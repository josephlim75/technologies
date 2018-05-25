# run zookeeper and kafka tasks in the background, and forward SIGTERM manually.
_term () {
  echo 'Caught SIGTERM'
  kill -TERM "$zookeeper" "$kafka"
}
trap _term SIGTERM

# start zookeeper
/kafka/bin/zookeeper-server-start.sh \
    /kafka/config/zookeeper.properties \
    &
zookeeper=$!


until timeout 1 bash -c "echo > /dev/tcp/localhost/2181"
do
	echo "waiting for zookeeper"
	sleep 1
done


# start kafka
/kafka/bin/kafka-server-start.sh \
    /kafka/config/server.properties \
    --override "advertised.host.name=${KAFKA_ADVERTISED_HOST_NAME}" \
    &
kafka=$!

# keep bash process alive until zookeeper and kafka terminate
wait "$zookeeper" "$kafka"