## List all mounts

  sudo systemctl --type mount
  cat /proc/mounts
  cat /etc/mtab
  findmnt
  mount

## Where and Mount path

Where=/mnt/backups

Filename needs to be mnt-backups.mount

## Mount file (mapr.mount)

/usr/lib/systemd/system

[Unit]
Description=MapR NFS mount DEV
Requires=network-online.target
After=network-online.target

[Mount]
What=10.32.48.39:/mapr
Where=/mapr
Options=rw,nolock,hard
Type=nfs

[Install]
WantedBy=multi-user.target


## Mounting via Systemd

Mount point with hyphens has to be escaped in systemd.  To escaped a mountpoint, the command below can be used

    $ systemd-escape -p --suffix=mount "/mapr/qa-red/tsys/"
    $ mapr-qa\x2dred-tsys.mount

To start a mount, `sudo systemctl start mapr-qa\\x2dred-tsys.mount`
    
### Stackoverflow reference

- [Systemd-hyphens-in-mount-point](https://superuser.com/questions/1101753/systemd-hyphens-in-mount-point)

Well the hyphen will be escaped when the unit is being created:

    [tom@localhost ~]$ udisksctl mount -b /dev/sdb1 
    Mounted /dev/sdb1 at /run/media/tom/A942-EE49.

    [tom@localhost ~]$ systemctl --type mount
    UNIT                             LOAD   ACTIVE SUB     DESCRIPTION
    ...
    run-media-tom-A942\x2dEE49.mount loaded active mounted /run/media/tom/A942-EE49
    ...

With some older version of systemd, you may need to escape the backslash of the escaped hyphen:

    [Unit]
    ...
    [Service]
    ...
    [Install]
    WantedBy=run-media-tom-A942\\x2dEE49.mount

However when I just tested it again with systemd 230, apparently you don't need to do that anymore. So:

    [Unit]
    ...
    [Service]
    ...
    [Install]
    WantedBy=run-media-tom-A942\x2dEE49.mount

should do.

FWIW, I think udisks2 prefers filesystem label over UUID if set.

P.S. The above case (WantedBy=) is just an example. It is used to make a service start (if enabled) with the mounting.    
    
## Convert DOS to GPT

parted /dev/sda
mklabel msdos
quit


MapR disk
============

maprcli disk list -host <host>
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Check disk / folders sizes
===========================
Find Out Top Directories and Files (Disk Space)
	/> du -a /home | sort -n -r | head -n 5
	/> find -type f -exec du -Sh {} + | sort -rh | head -n 5 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  
    
Wipeout disk
================
1) If you have data on the drive that you need to keep, back it up.

2) Fill the drive with zeros which will blow away the MBR, Partition table LVM and all data by:

sudo dd if=/dev/zero of=/dev/sdX

or if you want a progress report as you wipe the drive use

sudo dc3dd wipe=/dev/sdX in both cases sdX should be changed to sda, sdb, or whatever drive you are wiping. You can identify the drives using

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Fdisk
===============

fdisk -l
sudo fdisk -l

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Create files
==============
Linux & all filesystems
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
xfs_mkfile 10240m 10Gigfile

Linux & and some filesystems (ext4, xfs, btrfs and ocfs2)
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
fallocate -l 10G 10Gigfile

OS X, Solaris, SunOS and probably other UNIXes
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
mkfile 10240m 10Gigfile

HP-UX
>>>>>
prealloc 10Gigfile 10737418240

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Check iostats and network traffic
====================================
# iostat -d -t 5 10
Example : Display disk I/O partition statistics every five seconds a total of ten times

# iostat -p <disk>
Display I/O statistics for a particular disk and its partitions :

iostat -x -d /dev/md1 1
iostat -c -d -x -t -m /dev/md1 2 100
vmstat 3 5
watch -n 1 -d ifconfig eth0
iftop -i eth0
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Clearing Disk
Method 1 : 
fdisk /dev/sdb
dd if=/dev/zero of=/dev/sdb  bs=512  count=1
fdisk -l /dev/sdb
>>
Method 2
shred -n 5 -vz /dev/sdb
>>
Method 3
scrub -p dod /dev/sdb

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

lsblk

Check dm setup
===============
sudo dmsetup ls --tree
sudo dmsetup deps -o devname

sudo lvdisplay
sudo dmsetup info /dev/dm-0
sudo lvdisplay|awk  '/LV Name/{n=$3} /Block device/{d=$3; sub(".*:","dm-",d); print d,n;}'