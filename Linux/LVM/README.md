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
