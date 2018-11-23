https://serverfault.com/questions/791838/baffling-memory-leak-what-is-using-10gb-of-memory-on-this-system

free -h or free -g

cat /proc/meminfo

top -o %MEM -n 1

smem -tw
 
slabtop -o -s c




Use slabtop display kernel slab cache information:

    slabtop

Aslo see "vmstat -m":

    vmstat  -m

and look /proc/slabinfo:

    cat /proc/slabinfo

Drop cache to free memory

    sync; echo 3 > /proc/sys/vm/drop_caches

    \