## Reference Site
- https://pierrevillard.com/tag/haproxy/
- https://blog.bluematador.com/posts/running-haproxy-docker-containers-kubernetes/

## Backend Config
    backend app
      mode tcp
      balance roundrobin
      server  server1 192.168.1.12:80 check inter 2000 rise 2 fall 5
      server  server2 192.168.1.13:80 check inter 2000 rise 2 fall 5
