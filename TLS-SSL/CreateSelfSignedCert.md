## Configuring SSL Request

http://apetec.com/support/generatesan-csr.htm

```
  [req]
  distinguished_name = req_distinguished_name
  req_extensions = v3_req
  prompt = no

  [req_distinguished_name]
  countryName = US
  stateOrProvinceName = GA
  localityName = Columbus
  organizationalUnitName  = <name>
  commonName = <name>
  emailAddress = <email>

  [v3_req]
  subjectAltName = @alt_names

  [alt_names]
  DNS.1 = localhost
  DNS.2 = 127.0.0.1
  DNS.3 = *.<domain>
```

### Generate a private key

You'll need to make sure your server has a private key created:

    openssl genrsa -out san_domain_com.key 2048
  
### Create CSR file

Then the CSR is generated using:

    openssl req -new -out san_domain_com.csr -key san_domain_com.key -config openssl.cnf

### Print CSR Info

    openssl req -text -noout -in san_domain_com.csr
  
### Self-sign and create certificate

    openssl x509 -req -days 3650 -in san_domain_com.csr -signkey san_domain_com.key -out san_domain_com.crt -extensions v3_req -extfile openssl.cnf
  
### Print CERT Info

    openssl x509 -in san_domain_com.crt -text -noout

### Package the key and cert in PLCS12 file

The easiest way to install this into IIS is to first use openssl’s pkcs12 command to export both the private key and the certificate into a pkcs12 file:

    openssl pkcs12 -export -in san_domain_com.crt -inkey san_domain_com.key -out san_domiain_com.p12
  



