!connect jdbc:db2://10.200.128.64:1501/USTSYIQ10D datalkq1 eFTh1DtH
Select * From DLKDLK1T.TDL_SCHEDULE_END Fetch First 1 Rows Only;
Select * From TS2COM1T.TCH_DISC_PRVY_PLCY Fetch First 1 Rows Only;


!connect jdbc:mysql://10.32.49.194:3306/metastore hive mapr
!connect jdbc:mysql://10.121.132.35:3306/metastore hive mapr
!tables



!connect jdbc:drill:drillbit=10.32.12.113:31010
!connect jdbc:drill:drillbit=10.121.132.21:31010

sqlline –u jdbc:drill:[schema=<storage plugin>;]zk=<zk name>[:<port>][,<zk name2>[:<port>]... ]


!connect jdbc:hive2://10.32.49.194:10000


final String HIVE_JDBC_DRIVER = "org.apache.hive.jdbc.HiveDriver";

final String HIVE_JDBC_URL = "jdbc:hive2://<host>:10000/default;auth=maprsasl;saslQop=auth-conf;ssl=true";  

final String DRILL_JDBC_URL = “jdbc:drill:zk=<host>:5181/drill/<cluster-id>;schema=hive";

final String DRILL_JDBC_DRIVER = "org.apache.drill.jdbc.Driver";

final String DRILL_JDBC_USER="mapr";

final String DRILL_JDBC_PASSWORD=“mapr"; 