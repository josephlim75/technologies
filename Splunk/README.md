# Configuring Splunk user ACL

You can manually set the ACL with

sudo setfacl -m g:splunk:rx /var/log/messages
This will not persist as logrotate will not re-apply the ACL setting so for a more permanent solution I added a rule to logrotate to reset the ACL. I added the file..
```
/etc/logrotate.d/Splunk_ACLs
```
with

```
{
    postrotate
        /usr/bin/setfacl -m g:splunk:rx /var/log/cron
        /usr/bin/setfacl -m g:splunk:rx /var/log/maillog
        /usr/bin/setfacl -m g:splunk:rx /var/log/messages
        /usr/bin/setfacl -m g:splunk:rx /var/log/secure
        /usr/bin/setfacl -m g:splunk:rx /var/log/spooler
    endscript
}
```

Check the ACL status of a file with

```
$ getfacl /var/log/messages
```
For more info on ACL's see https://help.ubuntu.com/community/FilePermissionsACLs http://bencane.com/2012/05/27/acl-using-access-control-lists-on-linux/