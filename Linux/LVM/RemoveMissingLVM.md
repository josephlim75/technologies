Couldn't find device or unknow physical volume

```
  Couldn't find device with uuid WWeM0m-MLX2-o0da-tf7q-fJJu-eiGl-e7UmM3.
      --- Physical volume ---
      PV Name               unknown device
      VG Name               media
      PV Size               1,82 TiB / not usable 1,05 MiB
      Allocatable           yes (but full)
```      

Removing missing or unknow volume

```
# pvdisplay
Couldn't find device with uuid EvbqlT-AUsZ-MfKi-ZSOz-Lh6L-Y3xC-KiLcYx.
  --- Physical volume ---
  PV Name               /dev/sdb1
  VG Name               vg_srvlinux
  PV Size               931.51 GiB / not usable 4.00 MiB
  Allocatable           yes (but full)
  PE Size               4.00 MiB
  Total PE              238466
  Free PE               0
  Allocated PE          238466
  PV UUID               xhwmxE-27ue-dHYC-xAk8-Xh37-ov3t-frl20d

  --- Physical volume ---
  PV Name               unknown device
  VG Name               vg_srvlinux
  PV Size               465.76 GiB / not usable 3.00 MiB
  Allocatable           yes (but full)
  PE Size               4.00 MiB
  Total PE              119234
  Free PE               0
  Allocated PE          119234
  PV UUID               EvbqlT-AUsZ-MfKi-ZSOz-Lh6L-Y3xC-KiLcYx



# vgreduce --removemissing --force vg_srvlinux


  Couldn't find device with uuid EvbqlT-AUsZ-MfKi-ZSOz-Lh6L-Y3xC-KiLcYx.
  Removing partial LV LogVol00.
  Logical volume "LogVol00" successfully removed
  Wrote out consistent volume group vg_srvlinux

# pvdisplay

 --- Physical volume ---
  PV Name               /dev/sdb1
  VG Name               vg_srvlinux
  PV Size               931.51 GiB / not usable 4.00 MiB
  Allocatable           yes
  PE Size               4.00 MiB
  Total PE              238466
  Free PE               238466
  Allocated PE          0
  PV UUID               xhwmxE-27ue-dHYC-xAk8-Xh37-ov3t-frl20d
```
