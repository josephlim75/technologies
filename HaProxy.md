## SSL Passthrough

February 21, 2017 10.5k views  NGINX UBUNTU DEBIAN
How does one set up HAproxy for multiple domains, to multiple backends while passing through SSL? I would also be open to an nginx solution

Example in diagram for a better explanation:
```
                                backend_domain_a
  domain-a.com-.            .-> 123.123.123.123
               |            |
               +-> haproxy -+
               |            |   backend_domain_b
  domain-b.com-'            '-> 789.789.789.789
```
Note Each backend server will be issueing their own certificate. Hence the need for SSL passthrough.

I have this configuration, but doesn't work for multiple reasons (the key one being the missing port number):
```
frontend www
        bind *:80
        bind *:443
        option tcplog

        acl host_domain_a hdr(host) -i domain-a.com
        acl host_domain_b hdr(host) -i domain-b.com

        use_backend backend_domain_a if host_domain_a
        use_backend backend_domain_b if host_domain_b

backend backend_domain_a
        server web_a 123.123.123.123 check

backend backend_domain_b
        server web_b 789.789.789.789 check
```

In others words, I want Haxproxy to not terminate the SSL.

I initially wanted to do this with Nginx but apparently it can't act as a non-terminating point while reading the host details (though might be available in future versions with ssl preread)

## High Performance HAProxy (NBProc)

Multicore usage

https://trick77.com/dns-unblocking-using-dnsmasq-haproxy/

https://medium.freecodecamp.org/how-we-fine-tuned-haproxy-to-achieve-2-000-000-concurrent-ssl-connections-d017e61a4d27

## MapR HAProxy

#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    # to have these messages end up in /var/log/haproxy.log you will
    # need to:
    # 1) configure syslog to accept network log events.  This is done
    #    by adding the '-r' option to the SYSLOGD_OPTIONS in
    #    /etc/sysconfig/syslog
    # 2) configure local2 events to go to the /var/log/haproxy.log
    #   file. A line like the following can be added to
    #   /etc/sysconfig/syslog
    #
    #    local2.*                       /var/log/haproxy.log
    log         127.0.0.1 local2
    tune.chksize 32768
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon
    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats
#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    # option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000



#--------------------------------------------------------------------- 
#    __  __  ____ ____      _   _ ___
#   |  \/  |/ ___/ ___|    | | | |_ _|
#   | |\/| | |   \___ \    | | | || |
#   | |  | | |___ ___) |   | |_| || |
#   |_|  |_|\____|____/     \___/|___|
#---------------------------------------------------------------------
# Rules for MCS UI load balancing and HA on MapR : my.mapr01.fr 
#---------------------------------------------------------------------
 
frontend mapr-mcs-ui-ha-my.mapr01.fr
        bind *:8443
        option tcplog
        mode tcp
		default_backend mapr-mcs-ui-my.mapr01.fr

backend mapr-mcs-ui-my.mapr01.fr
		mode tcp
		option ssl-hello-chk
        balance first
        server node1 10.68.7.91:8443 check
        server node2 10.68.7.92:8443 check
        server node3 10.68.7.93:8443 check
        server node4 10.68.7.94:8443 check
        server node5 10.68.7.95:8443 check

#---------------------------------------------------------------------         
#   __  __    _    ____  ____         ____   _       ____    ____
#  |  \/  |  / \  |  _ \|  _ \       / ___| | |     |  _ \  | __ )
#  | |\/| | / _ \ | |_) | |_) |     | |     | |     | | | | |  _ \
#  | |  | |/ ___ \|  __/|  _ <      | |___  | |___  | |_| | | |_) |
#  |_|  |_/_/   \_\_|   |_| \_\      \____| |_____| |____/  |____/        
#---------------------------------------------------------------------
# Rules for MAPR CLDB on MapR cluster : my.mapr01.fr
#---------------------------------------------------------------------        
frontend mapr-cldb-ha-my.mapr01.fr
        bind *:7222
        option tcplog
        mode tcp
		default_backend mapr-cldb-ha-my.mapr01.fr

backend mapr-cldb-ha-my.mapr01.fr
		mode tcp
        balance first
        server node3 10.68.7.93:7222 check
        server node4 10.68.7.94:7222 check
        server node5 10.68.7.95:7222 check

frontend mapr-cldb-ui-ha-my.mapr01.fr
        mode http
        bind *:7221
        default_backend mapr-cldb-ui-ha-my.mapr01.fr

backend mapr-cldb-ui-ha-my.mapr01.fr
        balance static-rr
        option httpchk get /cldb.jsp
        http-check expect string MASTER_READ_WRITE
        default-server inter 3s fall 3 rise 2
        server node3 10.68.7.93:7221 check
        server node4 10.68.7.94:7221 check
        server node5 10.68.7.95:7221 check 
        
#--------------------------------------------------------------------- 
#   ____       _ _ _     _   _ ___
#  |  _ \ _ __(_) | |   | | | |_ _|
#  | | | | '__| | | |   | | | || |
#  | |_| | |  | | | |   | |_| || |
#  |____/|_|  |_|_|_|    \___/|___|
#---------------------------------------------------------------------
# Rules for Drill load balancing and HA on MapR : my.mapr01.fr
#---------------------------------------------------------------------
frontend drill-console-my.mapr01.fr
		mode http
		bind *:8047
		default_backend mapr-nodes-drillbits-my.mapr01.fr

backend mapr-nodes-drillbits-my.mapr01.fr
		balance static-rr
		server node1 10.68.7.91:8047 check
		server node2 10.68.7.92:8047 check
		server node3 10.68.7.93:8047 check
		server node4 10.68.7.94:8047 check
		server node5 10.68.7.95:8047 check

#---------------------------------------------------------------------
#   ____                                        __  __
#  |  _ \ ___  ___  ___  _   _ _ __ ___ ___    |  \/  | __ _ _ __
#  | |_) / _ \/ __|/ _ \| | | | '__/ __/ _ \   | |\/| |/ _` | '__|
#  |  _ <  __/\__ \ (_) | |_| | | | (_|  __/   | |  | | (_| | |
#  |_| \_\___||___/\___/ \__,_|_|  \___\___|   |_|  |_|\__, |_|
#                                                      |___/
#---------------------------------------------------------------------
# Rules for Resource Manager on MapR cluster : my.mapr01.fr
#---------------------------------------------------------------------
frontend resource-mgr-my.mapr01.fr
		mode http
		bind *:8088
		default_backend resource-mgr-my.mapr01.fr

backend resource-mgr-my.mapr01.fr
		balance static-rr
		server node3 10.68.7.93:8088 check
		server node4 10.68.7.94:8088 check
		server node5 10.68.7.95:8088 check
		
#---------------------------------------------------------------------
#   _   _ _     _                      ____
#  | | | (_)___| |_ ___  _ __ _   _   / ___| _ ____   __
#  | |_| | / __| __/ _ \| '__| | | |  \___ \| '__\ \ / /
#  |  _  | \__ \ || (_) | |  | |_| |   ___) | |   \ V /
#  |_| |_|_|___/\__\___/|_|   \__, |  |____/|_|    \_/
#                             |___/
#---------------------------------------------------------------------
# Rules for History Server on MapR cluster : my.mapr01.fr
#---------------------------------------------------------------------                           
frontend history-srv-my.mapr01.fr
		mode http
		bind *:19888
		default_backend history-srv-my.mapr01.fr

backend history-srv-my.mapr01.fr
		balance static-rr
		server node1 10.68.7.91:19888 check
		server node2 10.68.7.92:19888 check                                    

#---------------------------------------------------------------------
#   ____                   _         _   _ _     _
#  / ___| _ __   __ _ _ __| | __    | | | (_)___| |_ ___  _ __ _   _
#  \___ \| '_ \ / _` | '__| |/ /    | |_| | / __| __/ _ \| '__| | | |
#   ___) | |_) | (_| | |  |   <     |  _  | \__ \ || (_) | |  | |_| |
#  |____/| .__/ \__,_|_|  |_|\_\    |_| |_|_|___/\__\___/|_|   \__, |
#        |_|                                                   |___/
#---------------------------------------------------------------------
# Rules for Spark History on MapR cluster : my.mapr01.fr
#---------------------------------------------------------------------       
frontend spark-history-srv-my.mapr01.fr
		mode http
		bind *:18080
		default_backend spark-history-srv-my.mapr01.fr

backend spark-history-srv-my.mapr01.fr
		balance static-rr
		server node1 10.68.7.94:18080 check
		server node2 10.68.7.95:18080 check         

#---------------------------------------------------------------------
#   _   _ _             ____                               ____
#  | | | (_)_   _____  / ___|  ___ _ ____   _____ _ __    |___ \
#  | |_| | \ \ / / _ \ \___ \ / _ \ '__\ \ / / _ \ '__|     __) |
#  |  _  | |\ V /  __/  ___) |  __/ |   \ V /  __/ |       / __/
#  |_| |_|_| \_/ \___| |____/ \___|_|    \_/ \___|_|      |_____|
#---------------------------------------------------------------------
# Rules for Hive Server 2 on MapR cluster : my.mapr01.fr
#---------------------------------------------------------------------
frontend hiveserver2-ha-my.mapr01.fr
        bind *:10000
        option tcplog
        mode tcp
		default_backend hiveserver2-ha-my.mapr01.fr

backend hiveserver2-ha-my.mapr01.fr
		mode tcp
        balance first
        server node3 10.68.7.91:10000 check
        server node4 10.68.7.92:10000 check
    
#---------------------------------------------------------------------
# _   _ _             __  __      _           ____
#| | | (_)_   _____  |  \/  | ___| |_ __ _   / ___| _ ____   __
#| |_| | \ \ / / _ \ | |\/| |/ _ \ __/ _` |  \___ \| '__\ \ / /
#|  _  | |\ V /  __/ | |  | |  __/ || (_| |   ___) | |   \ V /
#|_| |_|_| \_/ \___| |_|  |_|\___|\__\__,_|  |____/|_|    \_/
#---------------------------------------------------------------------
# Rules for Hive Metaserver load balancing and HA on MapR : my.mapr01.fr
#---------------------------------------------------------------------                                   
frontend hivemeta-ha-my.mapr01.fr
        bind *:9083
        option tcplog
        mode tcp
		default_backend hivemeta-ha-my.mapr01.fr

backend hivemeta-ha-my.mapr01.fr
		mode tcp
        balance first
        server node1 10.68.7.91:9083 check
        server node2 10.68.7.92:9083 check    

#---------------------------------------------------------------------
#  _   _                   __    ___
# | | | |_   _  ___       / /   |_ _|_   ___   _
# | |_| | | | |/ _ \     / /     | |\ \ / / | | |
# |  _  | |_| |  __/    / /      | | \ V /| |_| |
# |_| |_|\__,_|\___|   /_/      |___| \_/  \__, |
#                                          |___/
#---------------------------------------------------------------------
# Rules for Hue & Ivy load balancing and HA on MapR : my.mapr01.fr
#---------------------------------------------------------------------                                   
frontend hue-console-my.mapr01.fr
		mode http
		bind *:8888
		default_backend hue-console-my.mapr01.fr

backend hue-console-my.mapr01.fr
		balance static-rr
		server node1 10.68.7.91:8888 check
		server node2 10.68.7.92:8888 check                                     

#--------------------------------------------------------------------- 
#   __  __             ____     ___    _
#  |  \/  |  _   _    / ___|   / _ \  | |
#  | |\/| | | | | |   \___ \  | | | | | |
#  | |  | | | |_| |    ___) | | |_| | | |___
#  |_|  |_|  \__, |   |____/   \__\_\ |_____|
#            |___/
#---------------------------------------------------------------------
# Rules for MySQL load balancing and HA on MapR : my.mapr01.fr
#---------------------------------------------------------------------
frontend mysql-ha-my.mapr01.fr
        bind *:3306
        option tcplog
        mode tcp
		default_backend mysql-ha-my.mapr01.fr

backend mysql-ha-my.mapr01.fr
		mode tcp
        balance first
        server node1 10.68.7.91:3306 check

        
#---------------------------------------------------------------------
#---------------------------------------------------------------------
#  ____  _        _         _   _    _    ____
# / ___|| |_ __ _| |_ ___  | | | |  / \  |  _ \ _ __ _____  ___   _
# \___ \| __/ _` | __/ __| | |_| | / _ \ | |_) | '__/ _ \ \/ / | | |
#  ___) | || (_| | |_\__ \ |  _  |/ ___ \|  __/| | | (_) >  <| |_| |
# |____/ \__\__,_|\__|___/ |_| |_/_/   \_\_|   |_|  \___/_/\_\\__, |
#                                                             |___/
#---------------------------------------------------------------------
#---------------------------------------------------------------------
listen stats *:1936
    stats enable
    stats uri /
    stats hide-version
stats auth openvpn:mapr
