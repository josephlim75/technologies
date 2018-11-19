https://serverfault.com/questions/791838/baffling-memory-leak-what-is-using-10gb-of-memory-on-this-system

free -h or free -g

cat /proc/meminfo

top -o %MEM -n 1

smem -tw
 
slabtop -o -s c