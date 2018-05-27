## Kill Supervisord process

    kill -s SIGTERM <supervisord pid>
        
## Controlling App with Supervisord

Is there a way to "gracefully" shutdown tomcat when controlling via supervisor?

    #!/bin/bash
    # Source: https://confluence.atlassian.com/plugins/viewsource/viewpagesrc.action?pageId=252348917
    function shutdown()
    {
        date
        echo "Shutting down Tomcat"
        unset CATALINA_PID # Necessary in some cases
        unset LD_LIBRARY_PATH # Necessary in some cases
        unset JAVA_OPTS # Necessary in some cases

        $TOMCAT_HOME/bin/catalina.sh stop
    }

    date
    echo "Starting Tomcat"
    export CATALINA_PID=/tmp/$$
    export JAVA_HOME=/usr/local/java
    export LD_LIBRARY_PATH=/usr/local/apr/lib
    export JAVA_OPTS="-Dcom.sun.management.jmxremote.port=8999 -Dcom.sun.management.jmxremote.password.file=/etc/tomcat.jmx.pwd -Dcom.sun.management.jmxremote.access.file=/etc/tomcat.jmxremote.access -Dcom.sun.management.jmxremote.ssl=false -Xms128m -Xmx3072m -XX:MaxPermSize=256m"

    # Uncomment to increase Tomcat's maximum heap allocation
    # export JAVA_OPTS=-Xmx512M $JAVA_OPTS

    . $TOMCAT_HOME/bin/catalina.sh start

    # Allow any signal which would kill a process to stop Tomcat
    trap shutdown HUP INT QUIT ABRT KILL ALRM TERM TSTP

    echo "Waiting for `cat $CATALINA_PID`"
    wait `cat $CATALINA_PID`
    
And here is what I used in /etc/supervisord.conf:

    [program:tomcat]
    directory=/usr/local/tomcat
    command=/usr/local/tomcat/bin/supervisord_wrapper.sh
    stdout_logfile=syslog
    stderr_logfile=syslog
    user=apache

Running, it looks like this:

    [root@qa1.qa:~]# supervisorctl start tomcat
    tomcat: started
    [root@qa1.qa:~]# supervisorctl status
    tomcat                           RUNNING    pid 9611, uptime 0:00:03
    [root@qa1.qa:~]# ps -ef|grep t[o]mcat
    apache    9611  9581  0 13:09 ?        00:00:00 /bin/bash /usr/local/tomcat/bin/supervisord_wrapper.sh start
    apache    9623  9611 99 13:09 ?        00:00:10 /usr/local/java/bin/java -Djava.util.logging.config.file=/usr/local/tomcat/conf/logging.properties -Dcom.sun.management.jmxremote.port=8999 -Dcom.sun.management.jmxremote.password.file=/etc/tomcat.jmx.pwd -Dcom.sun.management.jmxremote.access.file=/etc/tomcat.jmxremote.access -Dcom.sun.management.jmxremote.ssl=false -Xms128m -Xmx3072m -XX:MaxPermSize=256m -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -Djava.endorsed.dirs=/usr/local/tomcat/endorsed -classpath /usr/local/tomcat/bin/bootstrap.jar -Dcatalina.base=/usr/local/tomcat -Dcatalina.home=/usr/local/tomcat -Djava.io.tmpdir=/usr/local/tomcat/temp org.apache.catalina.startup.Bootstrap start


I tried initially to add those environment variables into /etc/supervisord.conf through the environment directive, but ran into trouble with the JAVA_OPTS, with all the spaces and equal signs. Putting it in the wrapper script took care of that.

Hope this helps save someone else some time!    


There is an "run" command in catalina.sh. It works perfectly fine with supervisor:

    [program:tomcat]
    command=/path/to/tomcat/bin/catalina.sh run
    process_name=%(program_name)s
    startsecs=5
    stopsignal=INT
    user=tomcat
    redirect_stderr=true
    stdout_logfile=/var/log/tomcat.log

The tomcat run as "catalina.sh run" works in foreground, has the correct pid and accepts signals. Works perfectly fine with supervisord.

Have you tried to use stopsignal=QUIT?

[program:tomcat]
command=java ...
process_name=tomcat
priority=150
startsecs=10
directory=./
stopsignal=QUIT
stdout_logfile=./logs/tomcat.log
stderr_logfile=./logs/tomcat.err