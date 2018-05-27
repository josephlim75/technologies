## Kafka working with Supervisord

### Option 1

I finally managed to get supervisor working with Kafka with two changes:

Deploy Kafka without -daemon flag, as supervisor requires non-daemozined process to manage
Explicitly define the Java path in supervisor configuration file
This is the working configuration:

#### start_kafka.sh

    JMX_PORT=17264 KAFKA_HEAP_OPTS="-Xms1024M -Xmx3072M" /home/kafka/kafka_2.11-0.10.1.0/bin/kafka-server-start.sh \
    /home/kafka/kafka_2.11-0.10.1.0/config/server.properties
    
#### supervisord.conf

    [unix_http_server]
    file=/var/run/supervisor.sock   ; (the path to the socket file)
    chmod=0700                       ; sockef file mode (default 0700)

    [supervisord]
    logfile=/var/log/supervisor/supervisord.log ; (main log file;default $CWD/supervisord.log)
    pidfile=/var/run/supervisord.pid ; (supervisord pidfile;default supervisord.pid)
    childlogdir=/var/log/supervisor            ; ('AUTO' child log dir, default $TEMP)

    ; the below section must remain in the config file for RPC
    ; (supervisorctl/web interface) to work, additional interfaces may be
    ; added by defining them in separate rpcinterface: sections
    [rpcinterface:supervisor]
    supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

    [supervisorctl]
    serverurl=unix:///var/run/supervisor.sock ; use a unix:// URL  for a unix socket

    ; The [include] section can just contain the "files" setting.  This
    ; setting can list multiple files (separated by whitespace or
    ; newlines).  It can also contain wildcards.  The filenames are
    ; interpreted as relative to this file.  Included files *cannot*
    ; include files themselves.

    [include]
    files = /etc/supervisor/conf.d/*.conf

    [program:kafka]
    command=/home/kafka/kafka_2.11-0.10.1.0/start_kafka.sh
    directory=/home/kafka/kafka_2.11-0.10.1.0
    user=root
    autostart=true
    autorestart=true
    stdout_logfile=/var/log/kafka/stdout.log
    stderr_logfile=/var/log/kafka/stderr.log
    environment = JAVA_HOME=/usr/lib/jvm/java-8-oracle


### Option 2
The following supervisor configuration file works for me, taken from 

https://github.com/miguno/wirbelsturm via https://github.com/miguno/puppet-kafka. 

The main difference is that it uses `kafka-run-class.sh` rather than `kafka-server-start.sh`.

Note that you'd need to update the various paths so it matches your setup, e.g. you must change `/opt/kafka/bin/kafka-run-class.sh` to    `/home/kafka/kafka_2.11-0.10.1.0/bin/kafka-run-class.sh`.

    [program:kafka-broker]
    command=/opt/kafka/bin/kafka-run-class.sh kafka.Kafka /opt/kafka/config/server.properties
    numprocs=1
    numprocs_start=0
    priority=999
    autostart=true
    autorestart=true
    startsecs=10
    startretries=999
    exitcodes=0,2
    stopsignal=INT
    stopwaitsecs=120
    stopasgroup=true
    directory=/
    user=kafka
    redirect_stderr=false
    stdout_logfile=/var/log/supervisor/kafka-broker/kafka-broker.out
    stdout_logfile_maxbytes=20MB
    stdout_logfile_backups=5
    stderr_logfile=/var/log/supervisor/kafka-broker/kafka-broker.err
    stderr_logfile_maxbytes=20MB
    stderr_logfile_backups=10
    environment=JMX_PORT=9999,KAFKA_GC_LOG_OPTS="-Xloggc:/var/log/kafka/daemon-gc.log -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCTimeStamps",KAFKA_HEAP_OPTS="-Xms512M -Xmx512M -XX:NewSize=200m -XX:MaxNewSize=200m",KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false",KAFKA_JVM_PERFORMANCE_OPTS="-server -XX:+UseCompressedOops -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:+CMSClassUnloadingEnabled -XX:+CMSScavengeBeforeRemark -XX:+DisableExplicitGC -Djava.awt.headless=true",KAFKA_LOG4J_OPTS="-Dlog4j.configuration=file:/opt/kafka/config/log4j.properties",KAFKA_OPTS="-XX:CMSInitiatingOccupancyFraction=70 -XX:+PrintTenuringDistribution"

    