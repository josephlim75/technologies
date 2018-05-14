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