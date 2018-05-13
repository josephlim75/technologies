```
#!/usr/bin/env bash

# HOW TO USE
# ./updateSecret.sh secretName newValue
# It's that simple !

if [ "$#" -ne 2 ];
  then
    echo "#####"
    echo "You must supplied secretName newValue"
    echo "ex : ./updateSecret.sh mongo_url \"mongodb://mongo:27017,mongo_2:27017,mongo_3:27017/myDB?replicaSet=rs0\""
    echo "#####"
    exit
fi

secretName=$1
newValue=$2

dateNow=$(date +%s%N)
sourceSecretName="$secretName"_"$dateNow"

# Check which service is using the secret name
function whoUseMySecret {
    local names=""

    # Loop into each service to catch IDS using that secret
    for name in $(docker service ls -q --format "{{.Name}}")
    do
      usingMySecret=$(docker service inspect $name | grep "\"$secretName\"" -c)
      if [ $usingMySecret -gt 0 ]; then
        names="$names:$name"
      fi
    done
    echo ${names#":"}
}

function getAllSecretsBeginWith {
  local names=""

  # Get all secrets name begin with the secret name
  # Useful to remove the oldests
  for name in $(docker secret ls -qf name="$secretName" --format "{{.Name}}")
    do
      names="$names:$name"
    done
    echo ${names#":"}
}

function updateSecret {

  local svNames=$1
  local scNames=$2

  # Transform into array
  svNames=(${svNames//:/ })
  scNames=(${scNames//:/ })

  # string to delete multiple secrets on a service
  deleteSecretsString=""
  for name in "${scNames[@]}"
  do
    deleteSecretsString="$deleteSecretsString --secret-rm $name"
  done

  # Update all services, remove the old secret, and then set the new, with the same target
  for name in "${svNames[@]}"
  do
    docker service update \
        $deleteSecretsString \
        --secret-add src="$sourceSecretName",target=$secretName \
        $name --detach=false
  done

  # Remove the oldests secrets
  for name in "${scNames[@]}"
  do
    docker secret rm $name
  done
}

function main {
  serviceNames=$(whoUseMySecret)
  echo "serviceNames = $serviceNames"
  secretsName=$(getAllSecretsBeginWith)
  echo $newValue | docker secret create $sourceSecretName -
  updateSecret $serviceNames $secretsName
}

main
```
