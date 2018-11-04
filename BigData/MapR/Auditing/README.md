## Grant user or group to read audit logs/cldbaudit

    hadoop mfs -setace -R -aces "rf:u:root|u:mapr|u:splunk,rd:u:root|u:mapr|u:splunk,ld:u:root|u:mapr|u:splunk" \
    /var/mapr/local/sample.qa.lab/audit/
 
 -Rm -- recursively modified
 
    sudo setfacl -Rm u:splunk:r,g:splunk:r /opt/mapr/mapr-cli-audit-log  (Files)
    sudo setfacl -m u:splunk:rx,g:splunk:rx /opt/mapr/mapr-cli-audit-log   (Directory)
    sudo setfacl -m d:u:splunk:rx,d:g:splunk:rx /opt/mapr/mapr-cli-audit-log   (Default Directory)
 
## Check if Audit feature is available

    maprcli config load -json | grep "mfs.feature.audit.support"
    
output example:

    auditing enabled: "mfs.feature.audit.support":"1"
    auditing disabled: "mfs.feature.audit.support":"0"
    
## Enabling cluster and data audit

    maprcli audit cluster -enabled true
    maprcli audit data -enabled true
    
- Cluster audit create the files in each node

    /opt/mapr/logs/initaudit.log.json
    /opt/mapr/logs/cldbaudit.log.json
    /opt/mapr/mapr-cli-audit-log/audit.log.json
    
- Check audit if audit is enabled

    maprcli audit info -json
    
# Audit level

1. Cluster level auditing (enabled/disabled)
2. - Volume level auditing (enabled/disabled)
3. - Directory, file, table level auditing (enabled/disabled)    


# Volume enable audit
    
    maprcli volume audit -name finance-project1 -enabled true -coalesce 5

# Directory / File / Table enable audit

    hadoop mfs -setaudit on|off <dir|file|table>
    
    
# Re-enable audit on existing files and directories

    find . -type d
    find . -type f
    find . -name '*'