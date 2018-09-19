## SSL Re-Encryption and HTTP Header Modification
- https://serverfault.com/questions/783881/haproxy-ssl-re-encryption-and-http-header-modification

I want to use my Haproxy 1.6.5 as Https load balancer before my https servers but I stuck with a problem of misunderstanding .

I want this behaviour: haproxy is available as https://example.com but behind it there are several https servers with self signed certs which I can't switch to http.

So I configured my tcp frontend for this as

```
frontend tcp_in
       mode tcp
       option tcplog
       bind *:443 ssl crt /etc/ssl/certs/server.bundle.pem
       maxconn 50000

   tcp-request inspect-delay 5s
   tcp-request content accept if { req.ssl_hello_type 1 }

   acl example_acl req.ssl_sni -i example.com
   use_backend special_example if example_acl
```
After this I want to send my traffic to one of the backends, but the point is I want to request something like https:\eimA.customer.local from backend1 and https:\eimB.customer.local from backend2 My guess is that I need to rewrite host header in request. (Probably it won't work in tcp mode. So how can I modify the config to do that ?)

My backend config is :
```
backend special_eims
        mode tcp
        option tcplog
        balance roundrobin
        stick-table type binary len 32 size 30k expire 30m
        acl clienthello req_ssl_hello_type 1
        acl serverhello rep_ssl_hello_type 2
        tcp-request inspect-delay 5s
        tcp-request content accept if clienthello
        tcp-response content accept if serverhello


        server eim1 eimA.customer.local:443 check
        server eim2 eimA.customer.local:443 check


        stick on payload_lv(43,1) if clienthello
        stick store-response payload_lv(43,1) if serverhello
```
As a result from my config I receive ssl connection error in browser and
```
curl -v https://example.com/default -k
* About to connect() to example.com port 443 (#0)
*   Trying 127.0.0.1... connected
* Connected to example.com (127.0.0.1) port 443 (#0)
* Initializing NSS with certpath: sql:/etc/pki/nssdb
* warning: ignoring value of ssl.verifyhost
* NSS error -12263
* Closing connection #0
* SSL connect error
curl: (35) SSL connect error
```
Direct connect to backend server with https: // ip-address/default returns 404 error so only https: //eimA.customer.local/default format are allowed.

Please help, sorry if the question is dumb.

I solved it after some time. 1. I switched from tcp to http mode, because in tcp mode you cannot get http header info. 2. Used real domain names in server statements and used http-send-name-header Host which basically sets host header to the name after server directive 3. For re-encryption mode front-end certificate is mandatory.

```
    frontend CUIC_frontend
           mode http
           bind *:443 ssl crt  /etc/ssl/certs/ssl-cert.pem
           option forwardfor
           option http-server-close
           reqadd X-Forwarded-Proto:\ https
    default_backend App_Backend
....
backend App_Backend
        mode http
        balance roundrobin
        http-send-name-header Host
        server full-application1-domain-name  10.10.10.1:443 cookie app1 check ssl verify none 
        server full-application2-domain-name 10.10.10.2:443 cookie app2 check ssl verify none 
```
