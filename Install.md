## Bootstrapping 

```
  ./add-host-sudoer.sh
  ansible-playbook -i <inventory> playbooks/host-partitions.yml
  ansible-playbook -i <inventory> playbooks/host-initialize.yml --skip-tags mapr-init,docker-init
  ansible-playbook -i <inventory> playbooks/host-repository.yml
  
```
