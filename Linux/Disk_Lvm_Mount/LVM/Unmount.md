## Understanding device busy

    # lsof | grep '/dev/sda1'

### How do I list the users on the file-system /nas01/?

Type the following command:

    # fuser -u /nas01/
    # fuser -u /var/www/
    
Linux fuser command to forcefully unmount a disk partition
Suppose you have /dev/sda1 mounted on /mnt directory then you can use fuser command as follows:

Warning examples may result into data lossWARNING! These examples may result into data loss if not executed properly (see “Understanding device error busy error” for more information).
Type the command to unmount /mnt forcefully:

    # fuser -km /mnt

Where,

-k : Kill processes accessing the file.
-m : Name specifies a file on a mounted file system or a block device that is mounted. In above example you are using /mnt
Linux umount command to unmount a disk partition.

You can also try the umount command with â€“l option on a Linux based system:

    # umount -l /mnt

Where,

-l : Also known as Lazy unmount. Detach the filesystem from the filesystem hierarchy now, and cleanup all references to the filesystem as soon as it is not busy anymore. This option works with kernel version 2.4.11+ and above only.
If you would like to unmount a NFS mount point then try following command:

    # umount -f /mnt

Where,

-f: Force unmount in case of an unreachable NFS system
Please note that using these commands or options can cause data loss for open files; programs which access files after the file system has been unmounted will get an error.
