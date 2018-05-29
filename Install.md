## Bootstrapping 

    ./add-host-sudoer.sh
    ansible-playbook -i <inventory> playbooks/host-partitions.yml
    ansible-playbook -i <inventory> playbooks/host-initialize.yml \
      --skip-tags mapr-init,docker-init
      
    ansible-playbook -i <inventory> playbooks/host-repository.yml
    
    ansible-playbook -i <inventory> playbooks/mapr-kafka.yml --tags umount/mount \
      --user mapr -e "@@credential.json"
      
    ansible-playbook -i <inventory> playbooks/mapr-eco-packages.yml -e "packages=hive,oozie" \
      --user mapr -e "@@credential.json"      

## Extend LVM

    # Set size to 300G
    sudo lvcreate -L 300G -n lv_docker vg_sys
    
    # +20G add 20G on top of existing size. Eg existing 10G, +20G = 30G
    sudo lvextend -L+20G vg_sys/lv_docker
    
    sudo xfs_growfs /dev/mapper/vg_sys-lv_docker
    
    # Extend and resize at the same time
    sudo lvresize --resizefs -L 100G /dev/mapper/vg_sys-lv_docker
    
## Reduzing LVM

### Unmount the volume

    # umount /var/lib/docker
    
### Reduce The Partition Size

    # lvreduce -L 400M /dev/vg00/lv00

### Format The Partition With XFS Filesystem

    # mkfs.xfs -f /dev/vg00/lv00

### Remount the Parition

    # mount /dev/vg00/lv00 /test

### Optional Backup / Restore
    Backup Data
    # xfsdump -f /tmp/test.dump /test
    Restore Data
    # xfsrestore -f /tmp/test.dump /test

## Mount LVM

    sudo mkdir /var/lib/docker; \
    sudo mkfs.xfs /dev/vg_sys/lv_docker; \
    sudo mount /dev/vg_sys/lv_docker /var/lib/docker
    
# Example
    # Find any process using the mount point
    sudo lsof | grep ' /opt'
    # Backup the mount point
    sudo xfsdump -f /var/opt.dump /opt; \
    sudo umount /opt; \
    sudo lvreduce -L 9.8G /dev/vg_sys/lv_opt; \
    sudo mkfs.xfs -f /dev/vg_sys/lv_opt; \
    sudo mount /dev/vg_sys/lv_opt /opt; \
    sudo xfsrestore -f /var/opt.dump /opt; \
    sudo rm -rf /var/opt.dump

    
