## HAProxy Setup With Subdomain

With TCP mode, HAProxy won't decode the HTTP request, so your acl lines won't do anything and the frontend will never be able to match a backend, as shown by the logs you entered: mytraffic/<NOSRV> means it wasn't able to pick a backend or server.

You'd have to split the 3 subdomains into 2 different frontends, each with their own IPs since they're all connecting on port 443. One for passthrough, the other for the SSL termination and content switching using mode http. The caveat here being that if you were to add a 4th subdomain (sub4.mydomain.com) that also required passthrough, you'd then need a 3rd frontend and IP.

You'd also need to create different CNAME or A records in DNS so that the right subdomains point to the right IPs.

Given this DNS config:
```
10.10.10.100        A         haproxy01-cs.mydomain.com
10.10.10.101        A         haproxy01-pt1.mydomain.com
10.10.10.102        A         haproxy01-pt2.mydomain.com
sub1.mydomain.com   CNAME     haproxy01-pt1.mydomain.com
sub2.mydomain.com   CNAME     haproxy01-cs.mydomain.com
sub3.mydomain.com   CNAME     haproxy01-cs.mydomain.com
sub4.mydomain.com   CNAME     haproxy01-pt2.mydomain.com
```

The HAproxy config would look something like this:
```
#Application Setup 
frontend ContentSwitching

  bind 10.10.10.100:443
  mode  http
  option httplog
  acl host_sub2 hdr(host) -i sub2.mydomain.com
  acl host_sub3 hdr(host) -i sub3.mydomain.com
  use_backend sub2_nodes if host_sub2
  use_backend sub3_nodes if host_sub3

frontend PassThrough1
  bind 10.10.10.101:443
  mode  tcp
  option tcplog
  use_backend sub1_nodes     

frontend PassThrough2
  bind 10.10.10.102:443
  mode  tcp
  option tcplog
  use_backend sub4_nodes

backend sub1_nodes
  mode tcp
  balance roundrobin
  stick-table type ip size 200k expire 30m
  stick on src
  server node1 10.10.10.101:8081 check
  server node2 10.10.10.102:8081 check 

backend sub2_nodes
  mode http
  balance roundrobin
  stick-table type ip size 200k expire 30m
  stick on src
  server node1 10.10.10.101:8082 check
  server node2 10.10.10.102:8082 check 

backend sub3_nodes
  mode http
  balance roundrobin
  stick-table type ip size 200k expire 30m
  stick on src
  server node1 10.10.10.101:8083 check
  server node2 10.10.10.102:8083 check

backend sub4_nodes
  mode tcp
  balance roundrobin
  stick-table type ip size 200k expire 30m
  stick on src
  server node1 10.10.10.101:8084 check
  server node2 10.10.10.102:8084 check
shareimprove this answer
```
