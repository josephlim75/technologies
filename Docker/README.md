## Docker Node Update

Changing node availability lets you:

- drain a manager node so that only performs swarm management tasks and is unavailable for task assignment.
- drain a node so you can take it down for maintenance.
- pause a node so it can’t receive new tasks.
- restore unavailable or paused nodes available status.
- For example, to change a manager node to Drain availability:

      $ docker node update --availability drain node-1

      node-1

## Docker Placement Preference

The following example sets a preference to spread the deployment across nodes based on the value of the `datacenter` label. 
If some nodes have `datacenter=us-east` and others have `datacenter=us-west`, the service is deployed as evenly as possible across the 
two sets of nodes.

    $ docker service create \
      --replicas 9 \
      --name redis_2 \
      --placement-pref 'spread=node.labels.datacenter' \
      redis:3.0.6

    create three node swarm, (node1, node2, node3) then:
    docker node update --label-add=azone=1 node1
    docker node update --label-add=azone=2 node2
    docker service create --placement-pref spread=node.labels.azone --replicas 2 --name spread nginx      
      
## Docker Prune or Cleanup

    docker rm -f $(docker ps -q -f "status=created" -f "status=exited"); \
    docker rmi -f $(docker images --filter "dangling=true" -q --no-trunc); \
    docker volume rm -f $(docker volume ls -qf dangling=true)

        
    docker system prune -a -f
    docker volume prune -f

## SSH to host with docker interactive

    ssh -tt -i myKey user@remoteHost docker exec -it myContainer /bin/bash

---------------------------------------------------------------------------------------------------------------------------
sed '/^FROM/aI LABEL test=test \\\n test2=test2' jenkins.df > jenkins@build.df

---------------------------------------------------------------------------------------------------------------------------
docker inspect -f '{{ index .Config.Labels "xxxxx" }}' <service>


---------------------------------------------------------------------------------------------------------------------------
docker service create --name cntlm -d \
--with-registry-auth \
--env CNTLM_SECRET=cntlm.key \
--env CNTLM_USER= \
--env CNTLM_DOMAIN=  \
--network tedp-net \
--publish 3128:3128 \
--secret cntlm.key \
artifactrepo.tpp.com:9095/edp-cntlm:0.92.3-alpine

---------------------------------------------------------------------------------------------------------------------------

Docker : failed to get default registry endpoint from daemon, permission denied
If you are getting error while running docker commands by non root user like

Warning: failed to get default registry endpoint from daemon (Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get http://%2Fvar%2Frun%2Fdocker.sock/v1.26/info: dial unix /var/run/docker.sock: connect: permission denied). Using system default: https://index.docker.io/v1/
Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Post http://%2Fvar%2Frun%2Fdocker.sock/v1.26/images/create?fromImage=alpine&tag=latest: dial unix /var/run/docker.sock: connect: permission denied

Add the non-root-user to group docker by updating /etc/group file or by running following command

usermod -aG docker non-root-user

---------------------------------------------------------------------------------------------------------------------------
