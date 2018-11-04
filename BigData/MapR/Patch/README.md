## Tez and Yarn containers

When Tez executed, the container resources is set at the `mapreduce.map.memory.mb`.  Then
we have to make sure that the hosts that runs this Tez containers has sufficient allocation
allow and that is set at `yarn.nodemanager.resource.memory-mb`, otherwise, you will get error

    mapreduce.map.memory.mb = 7168
    yarn.nodemanager.resource.memory-mb=5120

    Requested TaskResource=<memory:7168, vCores:1, disks:0>, 
    Cluster MaxContainerCapability=<memory:5120, vCores:4, disks:3>

Amount of physical memory, in MB, that can be allocated for containers. It means the amount 
of memory YARN can utilize on this node and therefore this property should be lower then the total memory 
of that machine.



## Post configuration after MapR 6.0.1 patch
sudo su mapr
cd /opt/mapr/tez/tez-0.8/
mkdir /opt/mapr/tez/tez-0.8/tez_lib_bkp
mv /opt/mapr/tez/tez-0.8/lib/hadoop-* /opt/mapr/tez/tez-0.8/tez_lib_bkp/
ls -1 /opt/mapr/tez/tez-0.8/tez_lib_bkp/ | sed 's/2.7.0-mapr-1710.jar/*/g' | while read line; do find /opt/mapr/hadoop -name $line | grep -v "test\|sources" |head -1 ; done | sort -u | xargs cp -t /opt/mapr/tez/tez-0.8/lib/
cd tez_lib_bkp/
cp /mapr/*/apps/tez/tez-0.8/lib/maprfs-6.0.1-mapr.jar /opt/mapr/tez/tez-0.8/lib/
cp /mapr/*/apps/tez/tez-0.8/lib/slf4j-log4j12-1.7.12.jar /opt/mapr/tez/tez-0.8/lib/
cp /mapr/*/apps/tez/tez-0.8/lib/slf4j-api-1.7.12.jar /opt/mapr/tez/tez-0.8/lib/
hadoop fs -rm -r /apps/tez/*;hadoop fs -put /opt/mapr/tez/tez-0.8 /apps/tez; hadoop fs -chmod -R 755 /apps/tez;

maprcli node services -name nodemanager -action restart -nodes `hostname`




