## Extending a Striped Volume
In order to increase the size of a striped logical volume, there must be enough free space on the underlying physical volumes that make up the volume group to support the stripe. For example, if you have a two-way stripe that that uses up an entire volume group, adding a single physical volume to the volume group will not enable you to extend the stripe. Instead, you must add at least two physical volumes to the volume group.
For example, consider a volume group vg that consists of two underlying physical volumes, as displayed with the following vgs command.

    # vgs
      VG   #PV #LV #SN Attr   VSize   VFree
      vg     2   0   0 wz--n- 271.31G 271.31G

You can create a stripe using the entire amount of space in the volume group.

    # lvcreate -n stripe1 -L 271.31G -i 2 vg
      Using default stripesize 64.00 KB
      Rounding up size to full physical extent 271.31 GB
      Logical volume "stripe1" created
    # lvs -a -o +devices
      LV      VG   Attr   LSize   Origin Snap%  Move Log Copy%  Devices
      stripe1 vg   -wi-a- 271.31G                               /dev/sda1(0),/dev/sdb1(0)

Note that the volume group now has no more free space.

    # vgs
      VG   #PV #LV #SN Attr   VSize   VFree
      vg     2   1   0 wz--n- 271.31G    0

The following command adds another physical volume to the volume group, which then has 135G of additional space.

    # vgextend vg /dev/sdc1
      Volume group "vg" successfully extended
    # vgs
      VG   #PV #LV #SN Attr   VSize   VFree
      vg     3   1   0 wz--n- 406.97G 135.66G

At this point you cannot extend the striped logical volume to the full size of the volume group, because two underlying devices are needed in order to stripe the data.

    # lvextend vg/stripe1 -L 406G
      Using stripesize of last segment 64.00 KB
      Extending logical volume stripe1 to 406.00 GB
      Insufficient suitable allocatable extents for logical volume stripe1: 34480 
    more required

To extend the striped logical volume, add another physical volume and then extend the logical volume. In this example, having added two physical volumes to the volume group we can extend the logical volume to the full size of the volume group.

    # vgextend vg /dev/sdd1
      Volume group "vg" successfully extended
    # vgs
      VG   #PV #LV #SN Attr   VSize   VFree
      vg     4   1   0 wz--n- 542.62G 271.31G
    # lvextend vg/stripe1 -L 542G
      Using stripesize of last segment 64.00 KB
      Extending logical volume stripe1 to 542.00 GB
      Logical volume stripe1 successfully resized

If you do not have enough underlying physical devices to extend the striped logical volume, it is possible to extend the volume anyway if it does not matter that the extension is not striped, which may result in uneven performance. When adding space to the logical volume, the default operation is to use the same striping parameters of the last segment of the existing logical volume, but you can override those parameters. The following example extends the existing striped logical volume to use the remaining free space after the initial lvextend command fails.

    # lvextend vg/stripe1 -L 406G
      Using stripesize of last segment 64.00 KB
      Extending logical volume stripe1 to 406.00 GB
      Insufficient suitable allocatable extents for logical volume stripe1: 34480 
    more required
    # lvextend -i1 -l+100%FREE vg/stripe1
    
## Shrinking Logical Volumes

To reduce the size of a logical volume, first unmount the file system. You can then use the lvreduce command to shrink the volume. After shrinking the volume, remount the file system.

Warning
It is important to reduce the size of the file system or whatever is residing in the volume before shrinking the volume itself, otherwise you risk losing data.
Shrinking a logical volume frees some of the volume group to be allocated to other logical volumes in the volume group.
The following example reduces the size of logical volume lvol1 in volume group vg00 by 3 logical extents.

    lvreduce -l -3 vg00/lvol1