## Zookeeper Production Configuration

A multi-node setup does require a few additional configurations. There is a comprehensive overview of these in the project documentation. Below is a concrete example configuration to help get you started.

      tickTime=2000
      dataDir=/var/lib/zookeeper/
      clientPort=2181
      initLimit=5
      syncLimit=2
      server.1=zoo1:2888:3888
      server.2=zoo2:2888:3888
      server.3=zoo3:2888:3888
      autopurge.snapRetainCount=3
      autopurge.purgeInterval=24


Command line remove topics
==========================
sudo ./zookeeper-shell.sh localhost:2181 rmr /brokers/topics/your_topic

Check Zookeeper status
=============================
echo stat | nc 127.0.0.1 2181

$ZOOKEEPER_HOME/bin/zkServer.sh qstatus

$ echo ruok | nc 127.0.0.1 5181
imok

---------------------------------------------------------------------------
ZooKeeper Commands: The Four Letter Words
ZooKeeper responds to a small set of commands. Each command is composed of four letters. You issue the commands to ZooKeeper via telnet or nc, at the client port.

dump
Lists the outstanding sessions and ephemeral nodes. This only works on the leader.

envi
Print details about serving environment

kill
Shuts down the server. This must be issued from the machine the ZooKeeper server is running on.

reqs
List outstanding requests

ruok
Tests if server is running in a non-error state. The server will respond with imok if it is running. Otherwise it will not respond at all.

srst
Reset statistics returned by stat command.

stat
Lists statistics about performance and connected clients.

Here's an example of the ruok command:

