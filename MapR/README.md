## MapR Administration

https://maprdocs.mapr.com/home/AdministratorGuide/ClstrAdminOverview.html

## Checking Ace Support

    # maprcli config load -json | grep "mfs.feature.db.ace.support" 
    "mfs.feature.db.ace.support":"0",
    
    # maprcli config save -values '{"mfs.feature.db.ace.support":"1"}'  

## MapR Installation

[MapR OS Support Matrix](https://mapr.com/docs/home/InteropMatrix/r_os_matrix_6.x.html)

OS Version | MapR 6.1.0 | MapR 6.0.1 | MapR 6.0.0 | MapR 5.2.2
--- | --- | --- | --- | ---
RHEL 7.5 |Yes |No | No | Yes
RHEL 7.4 |Yes |Yes |Yes | Yes

Mark down | Less | Pretty
--- | --- | ---
*Still* | `renders` | **nicely**
1 | 2 | 3
