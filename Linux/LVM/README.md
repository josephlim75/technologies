## Reference

http://unixadminschool.com/blog/2012/01/linux-lvm-cleaning-up-stale-storage-devices-from-lvm-after-storage-reclaim/

Device not found or rejected by filter - https://www.centos.org/forums/viewtopic.php?t=61324

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
