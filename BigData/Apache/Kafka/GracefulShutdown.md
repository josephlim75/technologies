In the Kafka configuration file (which in a standard setup is config/server.properties), enter the following configurations:

Copy
    controlled.shutdown.enable=true

Now start all the different nodes for Kafka.

Once all the nodes in your Kafka cluster are running, from the Kafka folder run the following command in the broker which you want to shut down.

Copy
    
    bin/kafka-server-stop.sh
    