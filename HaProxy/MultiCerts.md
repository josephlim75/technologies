## Configure HAProxy with Multiple Certificates

Ensure that you're running HAProxy 1.6 or higher
This question is a little old, but I ran into this exact same issue with configurations similar to the OP.
HAProxy 1.5 accepts the multiple crt syntax on a bind option; however, it uses only the first certificate when responding.
HAProxy 1.6 appears to respond with the certificate based on the caller's request. This does not appear to require any special sni ACLs in the config.
Here's an example that works on 1.6, but fails to use cert2.pem when responding to requests for place2.com on 1.5:

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
