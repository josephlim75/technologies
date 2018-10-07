## Reference
- [Generate Certs for IBM MQ and Java Client](https://developer.ibm.com/answers/questions/180659/how-do-you-set-up-ssl-2-way-authentication-between/)
- [Understanding Mutual Auth in IBM MQ](https://www-01.ibm.com/support/docview.wss?uid=nas8N1020262)

## Generate Client Certificate

    keytool -genkey \
      -alias tedp-mqclient \
      -dname "CN=TEDP MQ Client,O=TPP,OU=Datalake,C=US" \
      -keyalg RSA \
      -keysize 2048 \
      -keypass mqtest123 \
      -storepass mqtest123 \
      -keystore tedp-mqclient-keystore.jks
  
    keytool -importkeystore \
      -srckeystore tedp-mqclient-keystore.jks \
      -destkeystore tedp-mqclient-keystore.jks \
      -deststoretype pkcs12
  
    keytool -export \
      -alias tedp-mqclient \
      -storepass mqtest123 \
      -file tedp-mqclient.cer \
      -keystore /home/jlim/tedp-mqclient-keystore.jks
  
### Verify the Certificate in DER format

    openssl x509 -in tedp-mqclient.cer -inform der -text -noout

## Create Client request

    keytool -certreq \
      -alias tedp-mqclient \
      -keystore tedp-mqclient-keystore.jks \
      -storepass mqtest123 \
      -keypass mqtest123 \
      -file tedp-mqclient.req
      
### Import all the Public Certificates that require to be validated

    keytool -import \
      -alias tedp-mqclient \
      -v -trustcacerts \
      -file tedp-mqclient.cer \
      -keystore tedp-mqclient-truststore.jks \
      -keypass mqtruststore123 \
      -storepass mqtruststore123  

    keytool -import \
      -alias entrust-root-ca-ev \
      -v -trustcacerts \
      -file /entrust/rootCA_EV.cer \
      -keystore tedp-mqclient-truststore.jks \
      -keypass mqtruststore123 \
      -storepass mqtruststore123  
      
### List the keystore entries is added

    keytool -list -keystore tedp-mqclient-truststore.jks
    Enter keystore password:
    Keystore type: jks
    Keystore provider: SUN

    Your keystore contains 5 entries

    entrust-root-ca-standard, Aug 27, 2018, trustedCertEntry,
    Certificate fingerprint (SHA1): 8C:F4:27:FD:79:0C:3A:D1:66:06:8D:E8:1E:57:EF:BB:93:22:72:D4
    entrust-root-ca-ev, Aug 27, 2018, trustedCertEntry,
    Certificate fingerprint (SHA1): 8C:F4:27:FD:79:0C:3A:D1:66:06:8D:E8:1E:57:EF:BB:93:22:72:D4
    entrust-intermediate-ca-ev, Aug 27, 2018, trustedCertEntry,
    Certificate fingerprint (SHA1): CC:13:66:95:63:90:65:FA:B4:70:74:D2:8C:55:31:4C:66:07:7E:90
    entrust-intermediate-standard, Aug 27, 2018, trustedCertEntry,
    Certificate fingerprint (SHA1): F2:1C:12:F4:6C:DB:6B:2E:16:F0:9F:94:19:CD:FF:32:84:37:B2:D7
    tedp-mqclient, Aug 27, 2018, trustedCertEntry,
    Certificate fingerprint (SHA1): C6:07:C6:DF:4B:5F:2E:1B:73:89:C8:B0:E1:40:0B:99:8A:6B:E1:51
    