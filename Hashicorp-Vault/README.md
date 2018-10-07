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


http://cuddletech.com/?p=959
https://hackernoon.com/vault-as-ca-with-pki-backend-bbcfc315f06f
https://wiki.onap.org/display/DW/Signing+certificates+using+Vault+provided+CA%2C+and+the+CA+imported+into+Vault


Should have a look at this:

https://vaultproject.io/docs/secrets/ssh/index.html

Basically Vault (note the answer time) can create one time credential for people to use for SSH.

Most of its security back ends are focused on one time or short lease credentials which keeps rotating, and Vault becomes the central token vending machine.



G5 Hashicorp Vault
=====================
UAT: ecxxxxxx


Token to path.
curl -XPUT  -H "X-Vault-Token: xxxxxxx" -s http://vault-qa.tpp.com:8200/v1/auth/token/create
curl -H "X-Vault-Token: xxxxxxx"  http://vault-qa.tpp.com:8200/v1/sys/policy
curl -H "X-Vault-Token: xxxxxxx" -H "Content-Type: application/json" -X POST -d '{"policies":["datalake_otptoken"]}' http://vault-qa.tpp.com:8200/v1/auth/token/create

curl -k https://localhost:8200/v1/sys/health  (-k switch is when TLS is turned on)
http://vault-qa.tpp.com:8080/secrets/generic/secret/datalake/
curl -X GET --insecure -H "X-Vault-Token:xxxxxxx" http://vault-qa.tpp.com:8200/v1/secret/datalake/dev

LIST
curl -X GET --insecure -H "X-Vault-Token:xxxxxxx" -X LIST http://vault-qa.tpp.com:8200/v1/secret/datalake/
curl -X GET --insecure -H "X-Vault-Token:ecxxxxxx" -X LIST http://10.123.82.190:8200/v1/secret/datalake/

curl --header "X-Vault-Token: xxxxxxx" http://vault-qa.tpp.com:8200/v1/sys/mounts | python -m json.tool


curl --header "X-Vault-Token: xxxxxxx" -X LIST http://vault-qa.tpp.com:8200/v1/auth/token/datalake_admin/accessors

curl -X GET -H "X-Vault-Token: xxxxxxx" http://vault-qa.tpp.com:8200/v1/sys/auth
curl -X GET -H "X-Vault-Token: xxxxxxx" http://vault-qa.tpp.com:8200/v1/sys/policy/datalake_sudo

RENEW
======
curl -s -X POST -H "X-Vault-Token: xxxxxxx" -d "{\"increment\":\"90000h\"}" http://vault-qa.tpp.com:8200/v1/auth/token/renew-self


curl --header "X-Vault-Token: xxxxxxx" http://vault-qa.tpp.com:8200/v1/auth/token/lookup-self
{
    "auth": null,
    "data": {
        "accessor": "38f4f328-b49a-9f0a-9bdc-6a10ac048ffd",
        "creation_time": 1518200627,
        "creation_ttl": 360000000,
        "display_name": "token",
        "entity_id": "77a5c996-d351-eca6-0f7e-f62ace9de622",
        "expire_time": "2029-07-08T10:23:47.573108439Z",
        "explicit_max_ttl": 0,
        "id": "xxxxxxx",
        "issue_time": "2018-02-09T18:23:47.57310779Z",
        "meta": null,
        "num_uses": 0,
        "orphan": false,
        "path": "auth/token/create/datalake_admin",
        "policies": [
            "datalake_ro",
            "datalake_rw",
            "datalake_sudo",
            "default"
        ],
        "renewable": true,
        "role": "datalake_admin",
        "ttl": 357088699
    },
    "lease_duration": 0,
    "lease_id": "",
    "renewable": false,
    "request_id": "1c2ca001-87b8-ee69-36b7-2e4ba8e2644e",
    "warnings": null,
    "wrap_info": null
}

-----------------------------------------

 
From what I understand, the token you currently have is an admin token that allows full access within the datalake folder in Vault. From there, you can use the Vault APIs or UI to generate new policies, roles (with those policies), and tokens (which are linked to a role). In order to create new tokens, click the “+” next to “Auth Backends” where you can add the token backend. From there, you should be able to manage everything. If you are still unable to see the tools to create auth tokens, please try using the API/curl calls as well. From what I’ve recently learned, there are some limitations to using VaultUI, so using the API calls (through Postman or curl) may be more suitable for your purposes.
 
We have received an update regarding the PKI backend for managing certificates, as well. The URL for the PKI backend documentation and API are available:
https://www.vaultproject.io/docs/secrets/pki/index.html
https://www.vaultproject.io/api/secret/pki/index.html
 
The documentation can give an overview, and the API is how the other teams should be interacting with the backend. At the moment, VaultUI doesn’t support interacting with the PKI backend, so the API/curl calls will be the only method of interaction.
 
Please let me know if you have any additional issues or questions!
 
