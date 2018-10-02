## MapR Administration

https://maprdocs.mapr.com/home/AdministratorGuide/ClstrAdminOverview.html

## Checking Ace Support

    # maprcli config load -json | grep "mfs.feature.db.ace.support" 
    "mfs.feature.db.ace.support":"0",
    
    # maprcli config save -values '{"mfs.feature.db.ace.support":"1"}'  

## MapR Installation

### Upgrade to MapR 6.1.0
- [MapR OS Support Matrix](https://mapr.com/docs/home/InteropMatrix/r_os_matrix_6.x.html)

OS Version | MapR 6.1.0 | MapR 6.0.1 | MapR 6.0.0 | MapR 5.2.2
--- | --- | --- | --- | ---
RHEL 7.5 |Yes |No | No | Yes
RHEL 7.4 |Yes |Yes |Yes | Yes

### Data-on-wire-encryption
- Beginnning with MapR 6.1, data-on-wire-encryption is enabled by defualt for newly created volumes on secured clusters

### Metrics Monitoring
- MapR 6.1.0 requires a minimal level of metrics monitoring to be configured to support metering.
