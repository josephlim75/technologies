## Create Virtual IP for NFS

    maprcli virtualip add -cluster uat-red -macs "00:24:12:23:23:a0 xxxxx" \
    -netmask 255.255.254.0 -virtualip 10.121.129.21 -virtualipend 10.121.129.28
