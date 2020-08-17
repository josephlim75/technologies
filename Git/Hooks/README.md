https://github.com/adnanh/webhook



--> .git/hooks/post-commit

      #!/bin/sh

      function parse_git_hash() {
        git rev-parse --short HEAD 2> /dev/null | sed "s/\(.*\)/@\1/"
      }

      function changes() {
        git diff --name-only --diff-filter=AMDR --cached HEAD^
      }

      GIT_HASH=$(parse_git_hash)
      GIT_COUNT=$(changes | grep -Po "jenkins/" | wc -l)
      CRUMB=$(curl -ks 'https://jenkins:1a31ac9a96535f8351c685b61f7c629f@10.32.48.29:9443/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')

      curl -X POST -H $CRUMB http://10.32.48.29:8080/job/TEDP-Pipelines/job/TEDP-0001-Apps_Build_and_Package/build?token=1234567890 \
        --user jenkins:1a31ac9a96535f8351c685b61f7c629f \
        --data-urlencode json='{"parameter": [ {"name":"SLAVE_TARGET", "value":"TEDP_SLAVE"}, {"name":"GIT_BRANCH", "value":"release/1.0"}, {"name":"GIT_GOAL", "value":"clone"}, {"name":"GIT_URL", "value":"https://git.qa.tpp.tsysecom.com"}, {"name":"GIT_SSL_NO_VERIFY", "value":"true"}, {"name":"RELEASE_REGION", "value":"qa"}, {"name":"NEXUS_URL", "value":"http://artifactrepo.qa.tpp.tsysecom.com:8081/nexus/content/repositories/datalakelibraries"}, {"name":"MVN_MODULES", "value":"core,sqdata"}, {"name":"MVN_GOAL", "value":"clean install"}, {"name":"MVN_PROP", "value":"-DskipTests"}, {"name":"MVN_THREADS", "value":"8"}, {"name":"MAX_BUILD", "value":"90"}, {"name":"ANSIBLE_VERBOSITY", "value":"0"}]}'