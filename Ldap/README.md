ldapsearch -H "ldap://tsysdc1.tsys.tss.net:389" -C -s sub -x -W -D "CN=Quinn Smith,OU=4th Floor,OU=Building A,OU=Campus,OU=Columbus,OU=Georgia,OU=North America,OU=TSYS Users,DC=tsys,DC=tss,DC=net" -b "OU=TSYS Users,DC=tsys,DC=tss,DC=net" "(&(sAMAccountName=QuinnSmith))"

ldapsearch -H "ldap://tsysdevdc2.tsysdev.net:389" -C -s sub -x -W -D "CN=elk,OU=Service Accounts,OU=DataLake,OU=Unix,DC=tsysdev,DC=net" -b "OU=DataLake,OU=Unix,DC=tsysdev,DC=net" "(&(sAMAccountName=elk))"

ldapsearch -H "ldap://tsysdevdc2.tsysdev.net:389" -C -s sub -x -W -D "CN=elk,OU=Service Accounts,OU=DataLake,OU=Unix,DC=tsysdev,DC=net" -b "DC=tsysdev,DC=net" "(objectclass=TrustedDomain)"

ldapsearch -H "ldap://tsysdevdc2.tsysdev.net:389" -C -s sub -x -W -D "CN=elk,OU=Service Accounts,OU=DataLake,OU=Unix,DC=tsysdev,DC=net" -b "CN=tsys.tss.net,CN=System,DC=tsysdev,DC=net" "(&(sAMAccountName=QuinnSmith))"
