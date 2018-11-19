## OpenSSL command

- List CRL Pem

    openssl crl -inform DER -text -noout -inform PEM -in crl.pem

- Serial Number:
    
    $ openssl x509 -in CERTIFICATE_FILE -serial -noout

- Thumbprint:

    $ openssl x509 -in CERTIFICATE_FILE -fingerprint -noout

- Read from remove server
  
    $ openssl s_client -showcerts -connect ma.ttias.be:443

- Read from text file

    $ openssl x509 -text -noout -in <certificate> 
    
## Generate Self-signed Certificate

https://superuser.com/questions/226192/avoid-password-prompt-for-keys-and-prompts-for-dn-information

Edit: This is by far my most popular answer, and it's been a few years on now so I've added an ECDSA variant. If you can use ECDSA you should.

You can supply all of that information on the command line.

One step self-signed password-less certificate generation:

### RSA Version

	openssl req \
		-new \
		-newkey rsa:4096 \
		-days 365 \
		-nodes \
		-x509 \
		-subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" \
		-keyout www.example.com.key \
		-out www.example.com.cert

### ECDSA version

	openssl req \
		-new \
		-newkey ec \
		-pkeyopt ec_paramgen_curve:prime256v1 \
		-days 365 \
		-nodes \
		-x509 \
		-subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" \
		-keyout www.example.com.key \
		-out www.example.com.cert