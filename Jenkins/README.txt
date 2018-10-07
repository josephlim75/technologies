WebReference
==============
- https://www.cyotek.com/blog/using-parameters-with-jenkins-pipeline-builds
- http://vgaidarji.me/blog/2017/06/22/how-to-use-jenkins-plugins-in-jenkins-pipeline/

Jenkins Properties
=====================
properties([
  parameters([
    string(name: 'DEPLOY_ENV', defaultValue: 'TESTING', description: 'The target environment', )
   ])
])

Be warned that the emitted code including choices: ['TESTING', 'STAGING', 'PRODUCTION'] fails with an exception

java.lang.ClassCastException: hudson.model.ChoiceParameterDefinition.choices 
expects class java.lang.String but received class java.util.ArrayList
Instead, the list of choices has to be supplied as String containing new line characters 
(\n): choices: ['TESTING\nSTAGING\nPRODUCTION'] (JENKINS-40358).



Jenkins Plugins Download
========================
https://updates.jenkins-ci.org/download/plugins/

Jenkins CLI
===============
https://wiki.jenkins.io/display/JENKINS/Jenkins+Script+Console

https://wiki.jenkins.io/display/JENKINS/Jenkins+CLI
https://support.cloudbees.com/hc/en-us/articles/115001771692-How-to-Create-Permanent-Agents-with-Docker

SLAVE Connection via Webstart
=====================================
Download the slave.jar from MASTER.  no password required: - wget http://10.32.48.29:8080/jnlpJars/slave.jar

Connecto to MASTER with the Node name TEDP_SLAVE_WEB
java -jar slave.jar -jnlpCredentials <user>:<pass> -jnlpUrl http://10.32.48.29:8080/computer/TEDP_SLAVE_WEB/slave-agent.jnlp

wget http://jenkins-psa.qa.tpp.com:8080/jnlpJars/slave.jar

java -jar slave.jar -jnlpUrl http://jenkins-psa.qa.tpp.com:8080/computer/TDP_Slave/slave-agent.jnlp -secret 3fe0588820f0015a62f5b1194419f5afca960f4dd74195f1cd8c5855e02601


Pipeline Build
==============
https://jenkins.io/doc/pipeline/steps/pipeline-build-step/
----------------------------------------------------------------

build job: 'TEDP-001-Apps_Build_and_Package', parameters: [
    [$class: 'StringParameterValue', name: 'GIT_BRANCH', value: 'release/1.0']
]


build(job: 'jenkins-test-project-build', param1 : 'some-value')


Pipeline Syntax
==================
https://jenkins.io/doc/book/pipeline/syntax/


Using a Jenkinsfile 
====================
https://jenkins.io/doc/book/pipeline/jenkinsfile/



