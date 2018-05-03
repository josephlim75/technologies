The following command creates a logical volume 10 gigabytes in size in the volume group vg1.

    lvcreate -L 10G vg1

The following command creates a 1500 megabyte linear logical volume named testlv in the volume group testvg, creating the block device /dev/testvg/testlv.

    lvcreate -L1500 -ntestlv testvg

The following command creates a 50 gigabyte logical volume named gfslv from the free extents in volume group vg0.

    lvcreate -L 50G -n gfslv vg0

You can use the -l argument of the lvcreate command to specify the size of the logical volume in extents. You can also use this argument to specify the percentage of the volume group to use for the logical volume. The following command creates a logical volume called mylv that uses 60% of the total space in volume group testvol.

    lvcreate -l 60%VG -n mylv testvg

You can also use the -l argument of the lvcreate command to specify the percentage of the remaining free space in a volume group as the size of the logical volume. The following command creates a logical volume called yourlv that uses all of the unallocated space in the volume group testvol.

    lvcreate -l 100%FREE -n yourlv testvg

You can use -l argument of the lvcreate command to create a logical volume that uses the entire volume group. Another way to create a logical volume that uses the entire volume group is to use the vgdisplay command to find the "Total PE" size and to use those results as input to the the lvcreate command.

The following commands create a logical volume called mylv that fills the volume group named testvg.

    # vgdisplay testvg | grep "Total PE"
    Total PE              10230
    # lvcreate -l 10230 testvg -n mylv
    
## Mount to Logical Volume

Activate the volume:

    $ sudo vgchange -ay VolGroup00

Find the logical volume that has your Fedora root filesystem (mine proved to be LogVol00):

    $ sudo lvs

Create a mount point for that volume:

    $ sudo mkdir /mnt/fcroot

Mount it:

    $ sudo mount /dev/VolGroup00/LogVol00 /mnt/fcroot -o ro,user

You're done, navigate to /mnt/fcroot and copy the files and paste somewhere else.
