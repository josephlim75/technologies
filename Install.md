## Bootstrapping 

    ./add-host-sudoer.sh
    ansible-playbook -i <inventory> playbooks/host-partitions.yml
    ansible-playbook -i <inventory> playbooks/host-initialize.yml --skip-tags mapr-init,docker-init
    ansible-playbook -i <inventory> playbooks/host-repository.yml
  

## Create and Extend LVM

    sudo lvcreate -L 300G -n lv_docker vg_sys
    sudo lvextend -L+20G vg_sys/lv_docker


## Mount LVM

    sudo mkdir /var/lib/docker; \
    sudo mkfs.xfs /dev/vg_sys/lv_docker; \
    sudo mount /dev/vg_sys/lv_docker /var/lib/docker
    
    