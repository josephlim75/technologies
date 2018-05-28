## Blkid and Lsblk

- List all device UUID
```
  $ sudo blkid -c /dev/null -o list
  $ lsblk -f  (# not always work)
```
	
- Get UUID
```
  $ blkid -s UUID -o value <device Eg /dev/sda>
```	

- XFS /etc/fstab

XFS is pretty stable on its own. It's a mature filesystem. Mount/formatting options will really only impact performance. I set the allocation group count and the log size.

My usual mkfs.xfs command string is: mkfs.xfs -f -L /partitionname -d agcount=64 -l size=128m,version=2 /dev/sdb1

My mount options for a system with a battery-backed RAID controller are: rw,noatime,logbufs=8,logbsize=256k,nobarrier
