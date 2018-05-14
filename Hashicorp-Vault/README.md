I list all the command I used below for reproducing this problem:

	generate the self signed certificate
	openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365
	openssl rsa -in key.pem -out key.ins.pem

start the vault server in development mode, setup the env and auth-enable certificate

	vault server -dev
	export VAULT_ADDR=http://127.0.0.1:8200
	vault auth-enable cert

then write these information into the vault

	vault write auth/cert/certs/web display_name=web policies=root certificate=@cert.pem ttl=3600

Up TO NOW, all these commands go very well, then I try to use the commands below
	
	vault auth -method=cert -client-cert=cert.pem -client-key=key.ins.pem
	
or

	vault auth -method=cert -tls-skip-verify -client-cert=cert.pem -client-key=key.ins.pem
	
However, both of them return the error message as I describe in the very beginning

I'll appreciate it a lot if there is someone can help me!