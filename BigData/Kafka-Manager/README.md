
/kafka-manager -Dhttp.port=disabled -Dhttps.port=443

nohup bin/kafka-manager -Dkafka-manager.zkhosts="10.121.128.22:2181/kafka" -Dhttp.port=9000 -Dhttps.port=8443 &
