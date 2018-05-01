## MapR Administration

https://maprdocs.mapr.com/home/AdministratorGuide/ClstrAdminOverview.html

## Checking Ace Support

    # maprcli config load -json | grep "mfs.feature.db.ace.support" 
    "mfs.feature.db.ace.support":"0",
    
    # maprcli config save -values '{"mfs.feature.db.ace.support":"1"}'  
