The below test for 50Mbit

Server:
`iperf3 -s -p 5002 -i 1 -A 2 -V -B 172.16.200.10`

Client:
`iperf3 -c 172.16.200.10 -p 5002 -l 4096 -i 1 -A 6 -V -b 50M -u -T 200 -t 10 -B 172.16.200.11`

```
Results - 55% loss
200: Test Complete. Summary Results:
200: [ ID] Interval Transfer Bandwidth Jitter Lost/Total Datagrams
200: [ 4] 0.00-10.00 sec 59.0 MBytes 49.5 Mbits/sec 0.062 ms 8274/15114 (55%)
200: [ 4] Sent 15114 datagrams
200: CPU Utilization: local/sender 1.9% (0.2%u/1.7%s), remote/receiver 0.1% (0.0%u/0.0%s)
```

The below test results for 10M

Server:
`iperf3 -s -p 5002 -i 1 -A 2 -V -B 172.16.200.10`

Client:
`iperf3 -c 172.16.200.10 -p 5002 -l 4096 -i 1 -A 6 -V -b 10M -u -T 200 -t 10 -B 172.16.200.11`
```
Results - 21% loss
200: Test Complete. Summary Results:
200: [ ID] Interval Transfer Bandwidth Jitter Lost/Total Datagrams
200: [ 4] 0.00-10.00 sec 11.8 MBytes 9.90 Mbits/sec 0.143 ms 642/3019 (21%)
200: [ 4] Sent 3019 datagrams
200: CPU Utilization: local/sender 0.6% (0.1%u/0.5%s), remote/receiver 0.1% (0.0%u/0.1%s)
```
But when we observe for RX/TX packet counters from NIC Statistics no packet drop was observed. Both the end system Rx/Tx counters were same, but iperf3 shows packet loss.

Please suggest your opinion and ideas?

Thanks,
Srinivas

```
**./iperf3 -s -p 5002 -i 1 -A 10 -V -B 192.168.1.75 
200:  iperf 3.1.5
200:  200:  Linux dexsysEBS 3.13.0-117-generic #164-Ubuntu SMP Fri Apr 7 11:05:26 UTC 2017 x86_64
Control connection MSS 1448**
Warning:  UDP block size 4096 exceeds TCP MSS 1448, may result in fragmentation / drops
200:  Time: Fri, 12 May 2017 07:15:58 GMT
200:  Connecting to host 192.168.1.75, port 5002
200:        Cookie: dexsysEBS.1494573358.968135.5e774f75
200:  [  4] local 192.168.1.120 port 36396 connected to 192.168.1.75 port 5002
200:  Starting Test: protocol: UDP, 1 streams, 4096 byte blocks, omitting 0 seconds, 10 second test
200:  [ ID] Interval           Transfer     Bandwidth       Total Datagrams
200:  [  4]   0.00-1.00   sec  16.1 MBytes   135 Mbits/sec  4130  
200:  [  4]   1.00-2.00   sec  17.9 MBytes   150 Mbits/sec  4578  
200:  [  4]   2.00-3.00   sec  17.9 MBytes   150 Mbits/sec  4578  
200:  [  4]   3.00-4.00   sec  17.9 MBytes   150 Mbits/sec  4577  
200:  [  4]   4.00-5.00   sec  17.9 MBytes   150 Mbits/sec  4578  
200:  [  4]   5.00-6.00   sec  17.9 MBytes   150 Mbits/sec  4578  
200:  [  4]   6.00-7.00   sec  17.9 MBytes   150 Mbits/sec  4582  
200:  [  4]   7.00-8.00   sec  17.9 MBytes   150 Mbits/sec  4573  
200:  [  4]   8.00-9.00   sec  17.9 MBytes   150 Mbits/sec  4577  
200:  [  4]   9.00-10.00  sec  17.9 MBytes   150 Mbits/sec  4578  
200:  - - - - - - - - - - - - - - - - - - - - - - - - -
200:  Test Complete. Summary Results:
200:  [ ID] Interval           Transfer     Bandwidth       Jitter    Lost/Total Datagrams
200:  [  4]   0.00-10.00  sec   177 MBytes   149 Mbits/sec  0.030 ms  5426/45258 (12%)  
200:  [  4] Sent 45258 datagrams
200:  CPU Utilization: local/sender 2.9% (0.3%u/2.6%s), remote/receiver 1.5% (0.1%u/1.4%s)
200:  
200:  iperf Done.
```
