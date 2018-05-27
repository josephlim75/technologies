## Docker Signals

### Option 1

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

### Option 2

So, my docker-entrypoint.sh is like this:

    #!/bin/bash

    # SIGTERM-handler this funciton will be executed when the container receives the SIGTERM signal (when stopping)
    term_handler(){
       echo "***Stopping"
       /bin/tcsh ./my-cleanup-command
       exit 0
    }

    # Setup signal handlers
    trap 'term_handler' SIGTERM

    echo "***Starting"
    /bin/tcsh ./my-command

    # Running something in foreground, otherwise the container will stop
    while true
    do
       #sleep 1000 - Doesn't work with sleep. Not sure why.
       tail -f /dev/null & wait ${!}
    done