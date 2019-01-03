## Resize /var mount point
        Check if any process is using /var mount
        lsof | grep /var
        If sshd is using /var/tmp/host_0
        
        Set sshd KRB5RCACHEDIR to another location at /usr/lib/systemd/system/sshd.service
        Environment=KRB5RCACHEDIR=/tmp
        systemctl daemon-reload
        systemctl restart sshd
        
        # Create a user that have sudo access
        
        # Login with the user to stop all running services
        systemctl stop rpcbind.socket
        systemctl stop centrifydc
        systemctl stop rsyslog
        systemctl stop splunk
        systemctl stop gssproxy
        systemctl stop tuned
        systemctl stop postfix*
        systemctl stop vmware*
        systemctl stop chronyd
        systemctl stop rpc*
        systemctl stop systemd-journald.socket

        
        rm -rf /var/cache/yum /var/log/lastlog /var/log/audit/* /var/log/*.gz /var/log/vmware*.log*
        
        # Make a backup of /var 
        tar czfP var.tar.gz /var
        
        vgremove vg_docker
        sudo rm -rf /var/lib/docker

        lsof | grep /var
          -- make sure no process using /var
          -- make a backup of /var

        umount -l /var
        lvremove /dev/vg_sys/lv_var
        vgreduce vg_sys /dev/sdc
        vgreduce vg_sys /dev/sdd
        lvcreate -l+100%FREE -n lv_var vg_sys
        mkfs.ext4 /dev/vg_sys/lv_var
        mount /dev/vg_sys/lv_var /var
        
        sudo tar xzfP var.tar.gz -C /var

## Docker Overlay2
- Creating overlay2 lvm mount

        # sudo echo 'overlay' >> /etc/modules-load.d/overlay.conf
        # modprobe overlay
        # lsmod | grep overlay
        pvcreate /dev/sdb1 /dev/sdc1 /dev/sdd1

        vgcreate vg_docker /dev/sdb1
        vgextend vg_docker /dev/sdc1
        vgextend vg_docker /dev/sdd1
        lvcreate -l+100%FREE -n lv_var vg_docker
        mkfs.xfs -n ftype=1 /dev/vg_docker/lv_var
        mkdir -p /var/lib/docker
        mount /dev/vg_docker/lv_var /var/lib/docker
    
        # Make permanent mount point after reboot
        /etc/fstab
    
- Add into `/etc/docker/daemon.json` 

        {
          "storage-driver": "overlay2",
          "storage-opts": [
            "overlay2.override_kernel_check=true"
          ]
        }

## Update MapR Vault
```
# Compress
tar czf mapr.tar.gz mapr.login.conf maprserverticket mapruserticket ssl_keystore ssl_truststore

# Convert to encoded text
xxd -p mapr.tar.gz > mapr.txt

# Copy encoded text from Vault to input.txt.  Replace input.txt \n to newline
sed -i 's/\\n/\n/g' input.txt
xxd -r -p input.txt mapr.tar.gz

```

## Bootstrapping 
- Navigate to the ansible script path

- Create `@creds.json` file containing password

        {
          "ansible_ssh_pass": "xxxxxx",
          "hashivault_token": "xxxxx-xxxxx-xxxxx-xxxxx"
        }

- Set ANSIBLE_CONFIG

        export ANSIBLE_CONFIG=$(pwd)/conf/ansible.cfg
        
- List the hosts under group cluster
         
         # ansible -i inventory/qa cluster --list-hosts
         # ansible-playbook -i inventory/qa -u ansible -e "@@creds.json" playbooks/host-prepare.yml --list-hosts
         
- Host Preparation

         ansible-playbook -i inventory/qa --limit='node9' -u ansible -e "@@creds.json" playbooks/host-prepare.yml --tags install-java

- Generate passwordless

        ansible-playbook -i inventory/qa -u mapr -e "@@creds.json" playbooks/host-passwordless.yml

- Add user directory in MapR file system /users

         # acl_group is only if group doesn't exists for the same user id
         $ ansible-playbook -i inventory/qa -e "@@creds.json" \
          -u mapr \
          -e "acl_group=xxxx" \
          playbooks/access_control.yml \
          --tags manage_mfs_homedir

- Running playbook 
        
        # ansible-playbook -i inventory/qa -e "@@creds.json" \
          -u mapr \
          --tags install,configure,up
          playbooks/mapr-install2.yml
        
        # ./add-host-sudoer.sh
        
        ansible-playbook -i <inventory> playbooks/host-partitions.yml
        
        ansible-playbook -i <inventory> playbooks/host-initialize.yml \
          --skip-tags mapr-init,docker-init

        ansible-playbook -i <inventory> playbooks/host-repository.yml

        ansible-playbook -i <inventory> playbooks/mapr-kafka.yml --tags umount/mount \
          --user mapr -e "@@credential.json"

- Installing Hive requires `mapr_pass` and `mariadb_hive_pass` values
        
        # Mapr password and hashivault token is in @creds.json file
        $ ansible-playbook -i inventory/qa -u mapr -e "@@creds.json" \
            playbooks/mapr-mep-install.yml \
            --tags pkg_yarn,install
            
        # Deprecated 
        $ ansible-playbook -i inventory/qa playbooks/mapr-eco-packages.yml  \
           -e "access_region=qa hashivault_token=xxxx" \
           -e "packages=hive" --user mapr -e "@@creds.json" \
           --skip-tags metastore

        $ ansible-playbook -i <inventory> playbooks/mapr-eco-packages.yml \
           -e "access_region=dev hashivault_token=xxxxxxxxxxx" \
           -e "packages=hive,oozie" \
          --user mapr -e "@@credential.json"

- Add operation configuration to host

        ansible-playbook -i <inventory> --limit 'all:!localhost' \
        --user xx \
        -e "@@creds.json" \
        playbooks/ops-config.yml \
        --tags config --ask-vault-pass

## Update Certificate
    ansible-playbook -i inventory/<env>  \
    -e "@@creds.json" -e "nodes=node10,node12" -u mapr \
    playbooks/ops-certs-config.yml --ask-vault-pass

## Reactivate LVM volume

When running `lvdisplay` shows LV exists but status as `NOT available`, this required to reactivate the volume group after attaching it.  To activate all the inactive volumes on the system, the command is

    vgchange -a y

## Extend LVM

    # Set size to 300G
    sudo lvcreate -L 300G -n lv_docker vg_sys
    
    # +20G add 20G on top of existing size. Eg existing 10G, +20G = 30G
    sudo lvextend -L+20G vg_sys/lv_docker
    
    # Resize the file system
    sudo xfs_growfs /dev/mapper/vg_sys-lv_docker
    
    # Extend and resize at the same time
    sudo lvresize --resizefs -L 100G /dev/mapper/vg_sys-lv_docker
    
## Reducing LVM

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

    
