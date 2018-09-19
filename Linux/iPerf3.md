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
