## Reference Site
- https://pierrevillard.com/tag/haproxy/
- https://blog.bluematador.com/posts/running-haproxy-docker-containers-kubernetes/

## Weight
```
frontend http-in
    bind *:80

    #python
    acl acl_python hdr(host) -i python.service.consul
    use_backend backend_python if acl_python

    #python-smooth
    acl acl_python-smooth hdr(host) -i python-smooth.service.consul
    use_backend backend_python-smooth if acl_python-smooth

    backend backend_python
        balance roundrobin
        option http-server-close
        server standalone_31005 192.168.10.10:31005 maxconn 32  weight 1
        server standalone_31003 192.168.10.10:31003 maxconn 32  weight 100
        server standalone_31002 192.168.10.10:31002 maxconn 32  weight 100
        server standalone_31006 192.168.10.10:31006 maxconn 32  weight 1


    backend backend_python-smooth
        balance roundrobin
        option http-server-close
        server standalone_31000 192.168.10.10:31000 maxconn 32  weight 100
        server standalone_31004 192.168.10.10:31004 maxconn 32  weight 1
        server standalone_31001 192.168.10.10:31001 maxconn 32  weight 100
```
## SSL Configuraiton
```
listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/gogs.imperial-legion.fr/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/gogs.imperial-legion.fr/privkey.pem; # managed by Certbot
    ssl_session_cache shared:le_nginx_SSL:1m; # managed by Certbot
    ssl_session_timeout 1440m; # managed by Certbot

    ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # managed by Certbot
    ssl_prefer_server_ciphers on; # managed by Certbot

    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256 ECDHE-ECDSA-AES256-GCM-SHA384 ECDHE-ECDSA-AES128-SHA ECDHE-ECDSA-AES256-SHA ECDHE-ECDSA-AES128-SHA256 ECDHE-ECDSA-AES256-SHA384 ECDHE-RSA-AES$

if ($scheme != "https") {
    return 301 https://$host$request_uri;
} # managed by Certbot
```

## Backend with SNI
- https://www.haproxy.com/blog/enhanced-ssl-load-balancing-with-server-name-indication-sni-tls-extension/
```
    # Adjust the timeout to your needs
    defaults
      timeout client 30s
      timeout server 30s
      timeout connect 5s

    # Single VIP with sni content switching
    frontend ft_ssl_vip
      bind 10.0.0.10:443
      mode tcp

      tcp-request inspect-delay 5s
      tcp-request content accept if { req_ssl_hello_type 1 }

      acl application_1 req_ssl_sni -i application1.domain.com
      acl application_2 req_ssl_sni -i application2.domain.com

      use_backend bk_ssl_application_1 if application_1
      use_backend bk_ssl_application_2 if application_2

      default_backend bk_ssl_default

    # Application 1 farm description
    backend bk_ssl_application_1
      mode tcp
      balance roundrobin

      # maximum SSL session ID length is 32 bytes.
      stick-table type binary len 32 size 30k expire 30m

      acl clienthello req_ssl_hello_type 1
      acl serverhello rep_ssl_hello_type 2

      # use tcp content accepts to detects ssl client and server hello.
      tcp-request inspect-delay 5s
      tcp-request content accept if clienthello

      # no timeout on response inspect delay by default.
      tcp-response content accept if serverhello

      stick on payload_lv(43,1) if clienthello

      # Learn on response if server hello.
      stick store-response payload_lv(43,1) if serverhello

      option ssl-hello-chk
      server server1 192.168.1.1:443 check
      server server2 192.168.1.2:443 check

    # Application 2 farm description
    backend bk_ssl_application_2
      mode tcp
      balance roundrobin

      # maximum SSL session ID length is 32 bytes.
      stick-table type binary len 32 size 30k expire 30m

      acl clienthello req_ssl_hello_type 1
      acl serverhello rep_ssl_hello_type 2

      # use tcp content accepts to detects ssl client and server hello.
      tcp-request inspect-delay 5s
      tcp-request content accept if clienthello

      # no timeout on response inspect delay by default.
      tcp-response content accept if serverhello

      stick on payload_lv(43,1) if clienthello

      # Learn on response if server hello.
      stick store-response payload_lv(43,1) if serverhello

      option ssl-hello-chk
      server server1 192.168.2.1:443 check
      server server2 192.168.2.2:443 check

    # Sorry backend which should invite the user to update its client
    backend bk_ssl_default
      mode tcp
      balance roundrobin

      # maximum SSL session ID length is 32 bytes.
      stick-table type binary len 32 size 30k expire 30m

      acl clienthello req_ssl_hello_type 1
      acl serverhello rep_ssl_hello_type 2

      # use tcp content accepts to detects ssl client and server hello.
      tcp-request inspect-delay 5s
      tcp-request content accept if clienthello

      # no timeout on response inspect delay by default.
      tcp-response content accept if serverhello

      stick on payload_lv(43,1) if clienthello

      # Learn on response if server hello.
      stick store-response payload_lv(43,1) if serverhello

      option ssl-hello-chk
      server server1 10.0.0.11:443 check
      server server2 10.0.0.12:443 check
```

## Backend Config
    backend app
      mode tcp
      balance roundrobin
      server  server1 192.168.1.12:80 check inter 2000 rise 2 fall 5
      server  server2 192.168.1.13:80 check inter 2000 rise 2 fall 5

Meaning that the backend will only be used if the host header starts with external-service-1-0.
    
    use_backend be_external-service-1-0 if { hdr_beg(host) -i external-service-1-0 }

But I also need to make sure HTTP is redirected to HTTPS. When I use:

    redirect scheme https if !{ ssl_fc }

in my HTTP frontend section of HAProxy config, I get all requests redireted to default backend, so the above-mentioned acl rules are ignored if the request is redirected from redirect scheme.

## Config Example

### Example 1

    frontend http-frontend
        bind 10.1.0.4:80
        redirect scheme https if !{ ssl_fc }

    frontend https-frontend
        bind 10.1.0.4:443 ssl crt /etc/ssl/haproxy.pem

        option httplog
        mode http

        acl is_local hdr_end(host) -i mirror.skbx.co
        acl is_kiev  hdr_end(host) -i kiev.skbx.co

        use_backend kiev if is_kiev
        default_backend wwwlocalbackend

    backend wwwlocalbackend
        mode http
        server 1-www 127.0.0.1:443

    backend kiev
        mode http
        server 1-www 10.8.0.6:443

### Example 2

    frontend http-in
        bind *:80

        acl host_domain1 hdr(host) -i domain1.lt
        use_backend nginx_web_http if host_domain1

    frontend http-in
        bind *:443

        acl host_domain1 hdr(host) -i domain1.lt
        use_backend nginx_web_https if host_domain1

    backend nginx_web_https
        mode http
        ssl crt /etc/ssl/domain1/ crt ./certs/ prefer-server-cipher
        option httplog
        option httpclose
        server nginx 192.168.2.101:8080 check

    backend nginx_web_http
        mode http
        option httplog
        option httpclose
        server nginx 192.168.2.101:8080 check
        
### Example 3

    global
       log 127.0.0.1  local0
       log 127.0.0.1  local1 notice
       #log loghost   local0 info
       maxconn 4096
       # chroot /usr/share/haproxy
       user haproxy
       group haproxy
       daemon
       #debug
       #quiet

    defaults
       log   global
       mode  http
       option   httplog
       option   dontlognull
       retries  3
       option redispatch
       maxconn  2000
       contimeout  5000
       clitimeout  50000
       srvtimeout  50000

    # Host HA-Proxy web stats on Port 3306 (that will confuse those script kiddies)
    listen HAProxy-Statistics *:3306
        mode http
        option httplog
        option httpclose
        stats enable
        stats uri /haproxy?stats
        stats refresh 20s
        stats show-node
        stats show-legends
        stats show-desc Workaround haproxy for SSL
        stats auth admin:ifIruledTheWorld
        stats admin if TRUE
### Example 4        
```
global
  maxconn 2000
  pidfile /var/run/haproxy.pid
  log     127.0.0.1 local0
  log     127.0.0.1 local1 notice

  # echo "" | nc -U /var/run/haproxy.sock
  stats   socket /var/run/haproxy.sock mode 777

resolvers tedpdns
  nameserver dns "${HAPROXY_DNS_ADDR}:${HAPROXY_DNS_PORT}"

defaults
  log         global
  mode        http
  option      dontlognull
  option      forwardfor
  option      httpclose
  option      httplog
  retries     3
  timeout     check    5s
  timeout     client   5s
  timeout     connect  10s
  timeout     server   10s

frontend web
  bind   *:80
  mode   http
  option http-server-close
  option forceclose

  default_backend docker_app

backend docker_app
  server app app.mynetwork:8080 check resolvers tedpdns resolve-prefer ipv4
```
