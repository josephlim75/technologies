## Nexus Swagger UI

    https://10.32.48.29:8443/swagger-ui
    
## Get the list of files in repository

    curl -k -X GET --header 'Accept: application/json' \
      'https://10.32.48.29:8443/service/rest/beta/assets?continuationToken=3f5cae01760233b6f5d4cbd34da22eb8&repository=raw-tedp-hosted'

   ContinuationToken is to continue listing
   
## Get repository list

    curl -k -X GET --header 'Accept: application/json' 'https://10.32.48.29:8443/service/rest/beta/repositories'
    
    URL : https://nexus.ops.tsysedp.org:8443/service/rest/v1/components?repository=raw-tedp-hosted