## Converting JKS to PEM

jks is a keystore, which is a Java thing

use keytool binary from Java.

### Export the .crt:

    keytool -export -alias mydomain -file mydomain.der -keystore mycert.jks

### Convert the cert to PEM:

    openssl x509 -inform der -in mydomain.der -out certificate.pem
    
### Export the key:

    keytool -importkeystore -srckeystore mycert.jks -destkeystore keystore.p12 -deststoretype PKCS12

### Convert PKCS12 key to unencrypted PEM:

    openssl pkcs12 -in keystore.p12  -nodes -nocerts -out mydomain.key

---

Here is what I do,

First export the key :

    keytool -importkeystore -srckeystore mycert.jks -destkeystore keystore.p12 -deststoretype PKCS12

For apache ssl certificate file you need certificate only:

    openssl pkcs12 -in keystore.p12 -nokeys -out my_key_store.crt

For ssl key file you need only keys:

    openssl pkcs12 -in keystore.p12 -nocerts -nodes -out my_store.key
