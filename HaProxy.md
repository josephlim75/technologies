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

https://medium.freecodecamp.org/how-we-fine-tuned-haproxy-to-achieve-2-000-000-concurrent-ssl-connections-d017e61a4d27


