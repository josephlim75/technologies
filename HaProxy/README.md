## Reference Site
- https://pierrevillard.com/tag/haproxy/
- https://blog.bluematador.com/posts/running-haproxy-docker-containers-kubernetes/

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
