## Install XFS System Utilities

First, you need to install XFS system utilities, which allow you to perform various XFS related administration tasks (e.g., format, expand, repair, setting up quota, change parameters, etc).

On Debian, Ubuntu or Linux Mint:

    $ sudo apt-get install xfsprogs

On Fedora, CentOS or RHEL:

    $ sudo yum install xfsprogs
    

## Create XFS

    $ sudo fdisk /dev/sdb
    
    $ sudo mkfs.xfs -f /dev/sdb1
    
    $ sudo mount -t xfs /dev/sdb1 /storage
    
    $ df -Th /storage
    /dev/sdb1  /storage xfs  defaults  0  0
    
## Extending size of xfs 

Check the whether free space is available in Volume group (vg_xfs) or not using below command :

    [root@linuxtechi ~]# vgs vg_xfs 
     VG #PV #LV #SN Attr VSize VFree
     vg_xfs 1 1 0 wz--n- 10.00g 4.00g
    [root@linuxtechi ~]#

So we will extend the file system by 3GB using lvextend command with “-r” option

    [root@linuxtechi ~]# lvextend -L +3G /dev/vg_xfs/xfs_db -r
    
As we can see above that the size of “/dev/vg_xfs/xfs_db” has been extended from 6 GB to 9GB

Note : If xfs is not based on LVM , the use the xfs_growsfs command as shown below :

    [root@linuxtechi ~]# xfs_growfs <Mount_Point> -D <Size>
    
The “-D size” option extend the file system to the specified size (expressed in file system blocks). Without the -D size option, xfs_growfs will extend the file system to the maximum size supported by the device.

## Repairing a damaged XFS filesystem within LVM2

I logged in as root and I checked that Slax had recognized the hard drive (/dev/sda in my case). I was able to see two partitions for the drive:

    brw-rw---- 1 root disk 8, 0 sep 23 12:20 /dev/sda
    brw-rw---- 1 root disk 8, 1 sep 23 12:20 /dev/sda1
    brw-rw---- 1 root disk 8, 2 sep 23 12:20 /dev/sda2
    
`sda1` is an ext2 partition outside the LVM (mounted as /boot) and sda2 is the partition containing the LVM.

So... so far I had the drive and the phisical partitions recognized, but I couldn't check the root partition yet, I needed access to the LVM logical volumes.
One of the good things about Slax is that it comes with LVM/LVM2 support out of the box, so I just used some tools to get the job done.
First I used vgscan to search for LVM information in all the available hard drives:

    vgscan -v --mknodes

The --mknodes parameter tells vgscan to create all the needed entries in /dev so you can use the LVM stuff.

It recognized the LVM information and created all the needed entries under /dev/mapper. The one that interested me the most was /dev/mapper/japones-root (in my case, in yours it will depend on the name you gave the volume) because that was the logical volume mounted as the root partition.
Ok, now I've found the LVM volumes, I needed to activate them, which could be done using vgchange:

    vgchange -a y

With that, I did activate all the logical volumes found.
Finally, I used the xfs_check and xfs_repair tools to perform all the needed tasks in the XFS filesystem and repair it:

    xfs_check /dev/mapper/japones-root
    xfs_repair /dev/mapper/japones-root

I found that the filesystem was quite corrupt and _xfs_repair had to do a lot of work on some parts of it, but the system worked just fine after rebooting back into Debian.
Once the _xfs_repair tool finished cleaning the filesystem I mounted it (to see if everything was working fine):

    mkdir /mnt/japones && mount /dev/mapper/japones-root /mnt/japones

And after checking everything was ok I just rebooted the machine, removed the Slax CD and tried Debian again.
Everything worked fine.