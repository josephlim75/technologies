## Configure HAProxy with Multiple Certificates
- https://serverfault.com/questions/721687/how-to-configure-haproxy-for-multiple-ssl-certificates/721689

Ensure that you're running HAProxy 1.6 or higher
This question is a little old, but I ran into this exact same issue with configurations similar to the OP.
HAProxy 1.5 accepts the multiple crt syntax on a bind option; however, it uses only the first certificate when responding.
HAProxy 1.6 appears to respond with the certificate based on the caller's request. This does not appear to require any special sni ACLs in the config.
Here's an example that works on 1.6, but fails to use cert2.pem when responding to requests for place2.com on 1.5:

```
frontend apache-https
    bind 192.168.56.150:443 ssl crt /certs/crt1.pem crt /certs/cert2.pem
    reqadd X-Forwarded-Proto:\ https
    default_backend apache-http

backend apache-http
    redirect scheme https if { hdr(Host) -i www.example.com } !{ ssl_fc }
    redirect scheme https if { hdr(Host) -i api.example.com } !{ ssl_fc }
    ...
```

### Full Config

```
global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

    # Default SSL material locations
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    ssl-default-bind-ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS
    ssl-default-bind-options no-sslv3
    tune.ssl.default-dh-param 2048 // better with 2048 but more processor intensive

defaults
        log     global
        mode    http
        option tcplog
        option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000

frontend apache-http
        bind 0.0.0.0:80
        mode http
        option http-server-close                # needed for forwardfor
        option forwardfor                       # forward IP Address of client
        reqadd X-Forwarded-Proto:\ http
        default_backend apache-http
        stats enable

frontend apache-https
        bind 0.0.0.0:443 ssl crt cer1.pem cert2.pem
        reqadd X-Forwarded-Proto:\ https
        default_backend apache-http

backend apache-http
        redirect scheme https if { hdr(Host) -i db.example.com } !{ ssl_fc }
        redirect scheme https if { hdr(Host) -i api2.example.com } !{ ssl_fc }
        balance roundrobin
        cookie SERVERID insert indirect nocache
        server www-1 10.0.0.101:80 cookie S1 check
        server www-2 10.0.0.102:80 cookie S2 check
        server www-3 10.0.0.103:80 cookie S3 check
```
```
frontend http-in
        bind *:80
        bind *:443 ssl crt cert1.pem crt cert2.pem
        mode http

        acl common_dst hdr(Host) -m str place1.com place2.com

        use_backend be_common if common_dst

backend be_common
        # nothing special here.
```
