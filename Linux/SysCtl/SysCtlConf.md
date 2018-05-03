## Enable IPv4 packet forwarding.

Add the following to /etc/sysctl.conf: `net.ipv4.ip_forward = 1`

Apply the sysctl settings: `sysctl -p`

Add direct rules to firewalld. Add the --permanent option to keep these rules across restarts.
	
	firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -o eth_ext -j MASQUERADE
	firewall-cmd --direct --add-rule ipv4 filter FORWARD 0 -i eth_int -o eth_ext -j ACCEPT
	firewall-cmd --direct --add-rule ipv4 filter FORWARD 0 -i eth_ext -o eth_int -m state --state RELATED,ESTABLISHED -j ACCEPT
