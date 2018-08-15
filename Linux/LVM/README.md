## Reference

http://unixadminschool.com/blog/2012/01/linux-lvm-cleaning-up-stale-storage-devices-from-lvm-after-storage-reclaim/

Device not found or rejected by filter - https://www.centos.org/forums/viewtopic.php?t=61324

## Reactivate LVM volume

When running `lvdisplay` shows LV exists but status as `NOT available`, this required to reactivate the volume group after attaching it.  To activate all the inactive volumes on the system, the command is

    vgchange -a y

## Remove Volume Group

You cannot use --removemissing or force delete VG if metadata area equal zero as in my case.

Make block device from file and include in VG:

```
dd if=/dev/zero of=/tmp/tmp.raw bs=1M count=100
losetup -f
losetup /dev/loop0 /tmp/tmp.raw
vgextend $VG /dev/loop0
```
After that I have Metadata Areas        1

    vgremove $VG -force

and remove `pvdevice pvremove /dev/loop0`

## Show "unknow device"

When an LVM volume group is activated, it displays an "unknown device" error. The logical volumes will not activate.

        # pvscan
        Couldn't find device with uuid '56ogEk-OzLS-cKBc-z9vJ-kP65-DUBI-hwZPSu'.
        Couldn't find device with uuid '56ogEk-OzLS-cKBc-z9vJ-kP65-DUBI-hwZPSu'.
        PV /dev/sdb VG ops lvm2 [200.00 MB / 0 free]
        PV unknown device VG ops lvm2 [200.00 MB / 0 free]
        PV /dev/sdd VG sales ops [200.00 MB / 150.00 MB free]
        Total: 4 [600.00 MB] / in use: 4 [600.00 MB] / in no VG: 0 [0 ]

When When a physical disk is removed from a volume group containing multiple disks, it will also result in a paritial mode volume group. In the example below, the lrg volume group is missing one of its disks, resulting in partial mode.

        # /sbin/vgs
          Couldn't find device with uuid ntc7O9-wevl-ZtXz-xESe-wwUB-G8WZ-6RtjxB.
          VG   #PV #LV #SN Attr   VSize   VFree  
          asm    1   2   0 wz--n- 300.00m  60.00m
          ceo    1   1   0 wz--n- 252.00m  12.00m
          lrg    4   1   0 wz-pn-   1.19g 716.00m
          sys    1   3   0 wz--n-   3.50g  12.00m
          
Generally this error means the physical device is missing or the LVM meta data on the device is corrupted or missing. The general procedure to recover the volume is:

1. Replace the failed or missing disk
2. Restore the missing disk's UUID
3. Restore the LVM meta data
4. Repair the file system on the LVM device

Scenario 1:
If the disk was just removed without preparing LVM, then just put the disk back in the server and reboot. If you intend to remove the device, first remove the disk from the volume group, then from the server.

Scenario 2:
If the disk is installed in the server, but still unknown, the LVM meta data may be missing. You need to restore the UUID for the device as displayed by pvscan, and then run vgcfgrestore to restore the LVM meta data. For example,

        # pvcreate --uuid 56ogEk-OzLS-cKBc-z9vJ-kP65-DUBI-hwZPSu /dev/sdc
        # vgcfgrestore ops
        # vgchange -ay ops
        # fsck /dev/ops/

NOTE: Make sure you use the correct UUID, as displayed by pvscan. Otherwise, the vgcfgrestore may fail. 

### LVM Performance

https://unix.stackexchange.com/questions/7122/does-lvm-impact-performance

LVM is designed in a way that keeps it from really getting in the way very much. From the userspace point of view, it looks like another layer of "virtual stuff" on top of the disk, and it seems natural to imagine that all of the I/O has to now pass through this before it gets to or from the real hardware.

But it's not like that. The kernel already needs to have a mapping (or several layers of mapping actually) which connects high level operations like "write this to a file" to the device drivers which in turn connect to actual blocks on disk.

When LVM is in use, that lookup is changed, but that's all. (Since it has to happen anyway, doing it a bit differently is a negligible performance hit.) When it comes to actually writing the file, the bits take as direct a path to the physical media as they would otherwise.

There are cases where LVM can cause performance problems. You want to make sure the LVM blocks are aligned properly with the underlying system, which should happen automatically with modern distributions. And make sure you're not using old kernels subject to bugs like this one. Oh, and using LVM snapshots degrades performance (and increasingly so with each active snapshot). But mostly, the impact should be very small.

As for the last: how can you test? The standard disk benchmarking tool is bonnie++. Make a partition with LVM, test it, wipe that out and (in the same place, to keep other factors identical) create a plain filesystem and benchmark again. They should be close to identical.



LVM, like everything else, is a mixed blessing.

With respect to performance, LVM will hinder you a little bit because it is another layer of abstraction that has to be worked out before bits hit (or can be read from) the disk. In most situations, this performance hit will be practically unmeasurable.

The advantages of LVM include the fact that you can add more storage to existing filesystems without having to move data around. Most people like it for this advantage.

One disadvantage of LVM used in this manner is that if your additional storage spans disks (ie involves more than one disk) you increase the likelyhood that a disk failure will cost you data. If your filesystem spans two disks, and either of them fails, you are probably lost. For most people, this is an acceptable risk due to space-vs-cost reasons (ie if this is really important there will be a budget to do it correctly) -- and because, as they say, backups are good, right?

For me, the single reason to not use LVM is that disaster recovery is not (or at least, was not) well defined. A disk with LVM volumes that had a scrambled OS on it could not trivially be attached to another computer and the data recovered from it; many of the instructions for recovering LVM volumes seemed to include steps like go back in time and run vgcfgbackup, then copy the resulting /etc/lvmconf file to the system hosting your hosed volume. Hopefully things have changed in the three or four years since I last had to look at this, but personally I never use LVM for this reason.

That said.

In your case, I would presume that the VMs are going to be relatively small as compared to the host system. This means to me you are more likely to want to expand storage in a VM later; this is best done by adding another virtual disk to the VM and then growing the affected VM filesystems. You don't have the spanning-multiple-disks vulnerability because the virtual disks will quite likely be on the same physical device on the host system.

If the VMs are going to have any importance to you at all, you will be RAID'ing the host system somehow, which will reduce flexibility for growing storage later. So the flexibility of LVM is probably not going to be required.

So I would presume you would not use LVM on the host system, but would install VMs to use LVM.

In general: If you add a new layer of complexity ("aka more to do") nothing will be faster. Note: You only add work and not 'change' they way the work is done.

How can you measure something? Well, you create one partition with LVM and one without, then use a normal benchmark and just run it. Like the folks at

http://www.umiacs.umd.edu/~toaster/lvm-testing/

As it seems, only slightly impact to the speed. That seems to by in sync with the findings of someone else who ran a benchmark:

http://lists-archives.org/linux-kernel/27323152-ext4-is-faster-with-lvm-than-without-and-other-filesystem-benchmarks.html

But just benchmark it on your own and see if your hardware and the OS you want to use behave the same and if you can ignore the (maybe slightly) impact of an additional layer of complexity which gives you elastic storage.

Should you add LVM to the guest OS: That depends on if you need the guest OS to have elastic storage as well, doesn't it? Your needs dictate what you have to deploy.


