
  246  20180312 10:00:42  iptables
  248  20180312 10:00:47  iptables -h
  249  20180312 10:00:50  iptables -l
  250  20180312 10:00:53  iptables --list
  251  20180312 10:01:09  iptables --check
  252  20180312 11:15:07  sudo iptables-restore /mapr/mapr-cluster/user/jlim/iptables.backup
  266  20180312 11:48:15  sudo iptables -S
  267  20180312 11:49:17  iptables-apply
  268  20180312 11:49:48  yum install iptables-apply
  269  20180312 11:49:51  sudo yum install iptables-apply
  270  20180312 11:50:07  sudo yum -whichpackage iptables-apply
  271  20180312 11:50:31  sudo yum -provides iptables-apply
  272  20180312 11:51:02  sudo yum whatprovides */iptables-apply
  302  20180312 12:01:35  sudo iptables -S
  303  20180312 12:01:54  sudo iptables-save > iptables.backup
  304  20180312 12:02:05  sudo iptables-save > ~/iptables.backup
  306  20180312 12:02:10  cat iptables.backup
  307  20180312 12:02:31  cp iptables.backup iptables.rm
  308  20180312 12:02:33  vi iptables.rm
  309  20180312 12:04:12  cp iptables.backup iptables.backup2
  310  20180312 12:04:15  vi iptables.backup
  311  20180312 12:04:17  vi iptables.backup2
  314  20180312 12:05:44  sudo iptables-restore /mapr/mapr-cluster/user/jlim/iptables.rm
  315  20180312 12:06:34  sudo iptables-restore /mapr/mapr-cluster/user/jlim/iptables.backup2
  876  20190402 08:58:50  vi iptables.rm
