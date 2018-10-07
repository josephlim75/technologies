$ sudo netstat -lntp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address               Foreign Address             State       PID/Program name
tcp        0      0 0.0.0.0:3306                0.0.0.0:*                   LISTEN      3686/mysqld
tcp        0      0 :::443                      :::*                        LISTEN      2218/httpd
tcp        0      0 :::80                       :::*                        LISTEN      2218/httpd
tcp        0      0 :::22                       :::*                        LISTEN


## Calculate Retransmit %

netstat -s | grep 'segments retransmited' | awk '{print $1}' -> 21983

netstat -s | grep 'segments send out' | awk '{print $1}' -> 91874454

21983/91874454 = .000239272
