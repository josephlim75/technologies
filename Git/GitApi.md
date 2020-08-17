Git api
=======

https://developer.atlassian.com/bitbucket/api/2/reference/resource/repositories/%7Busername%7D/%7Brepo_slug%7D/src/%7Bnode%7D/%7Bpath%7D
https://stackoverflow.com/questions/46804521/bitbucket-api-read-raw-file-from-branch-with-access-code
https://stackoverflow.com/questions/32732834/how-to-get-list-of-file-names-inside-a-specific-folder-in-stash-repository-using
https://api.bitbucket.org/1.0

curl -ks -u <credential> https://<url>/rest/api/1.0/projects/EDP/repos/<repo name>/browse/provisioning/edp-docker/images?at=release/1.0


curl -ks -u <credential> https://git.qa.tpp.com/rest/api/1.0/projects/EDP/repos/tedp-devops/browse/provisioning/edp-docker/images?at=release/1.0


curl -ks -u jlim:2019Son!! https://git.qa.tpp.com/rest/api/1.0/projects/EDP/repos/tedp-devops/browse/provisioning/edp-docker/images/exclude.conf?at=release/1.0&raw
curl -ks -u jlim:2018Amj! https://git.qa.tpp.com/rest/api/1.0/projects/EDP/repos/tedp-devops/browse/provisioning/edp-docker/images/exclude.conf?at=release/1.0 | jq

Get raw file
=============
curl -ks -u jlim:2018Amj! https://git.qa.tpp.com/projects/EDP/repos/tedp-devops/raw/provisioning/edp-docker/images/exclude.conf?at=release/1.0


Server}/{project}/repos/{reponame}/browse/{filename}?raw&at={version}