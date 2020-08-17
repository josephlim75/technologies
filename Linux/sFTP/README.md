# sFTP command line via proxy
  
  sftp -v -o ConnectTimeout=3 -o ProxyCommand='/usr/bin/nc --proxy-type http --proxy 10.124.127.15:80 %h %p' -P 115 tsys@sftp.mapr.com
  sftp -v -oConnectTimeout=3 -oProxyCommand='/usr/bin/nc --proxy-type http --proxy 10.124.127.15:80 %h %p' -oPort=115 tsys@sftp.mapr.com

# Check website against proxy

  ncat --proxy dmzproxy1.ebs.web:80 --ssl -vv sftp.mapr.com 443